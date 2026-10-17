import 'dart:convert';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/evaluation/controlled_evaluation_process.dart';

/// File operations for a controlled attempt. No candidate path is opened,
/// resolved, or enumerated by the host: the only authority is the guest process.
/// The trusted Python program receives bounded arguments and runs under the
/// same filesystem/network enclosure as candidate commands.
List<HarnessTool> controlledFileTools(ControlledEvaluationProcess process) => [
  _ControlledFileTool(ReadTool(), process),
  _ControlledFileTool(WriteTool(), process),
  _ControlledFileTool(EditTool(), process),
  _ControlledFileTool(SearchTool(), process),
  _ControlledFileTool(FindTool(), process),
];

/// Preserve the command policy while refusing a model-supplied cwd: the
/// ordinary BashTool resolves cwd symlinks on the host before running it.
class ControlledEvaluationBashTool extends HarnessTool {
  /// Runs Bash through the enclosure without exposing its host-side cwd path.
  ControlledEvaluationBashTool(ControlledEvaluationProcess process)
    : _delegate = BashTool(process);

  final BashTool _delegate;

  @override
  String get name => _delegate.name;
  @override
  String get description =>
      '${_delegate.description} '
      'Commands always run from the attempt workspace root; cwd is unavailable.';
  @override
  Map<String, dynamic> get inputSchema {
    final schema = _delegate.inputSchema;
    final props = Map<String, dynamic>.from(schema['properties'] as Map);
    props.remove('cwd');
    return {...schema, 'properties': props};
  }

  @override
  ToolApprovalTier get approvalTier => _delegate.approvalTier;
  @override
  bool get selfGuards => _delegate.selfGuards;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) {
    if (args.containsKey('cwd')) {
      return Future.value(
        HarnessToolResult.error(
          'Controlled evaluation commands use the attempt workspace root; '
          'cwd cannot be set.',
        ),
      );
    }
    return _delegate.execute(args, context);
  }
}

class _ControlledFileTool extends HarnessTool {
  _ControlledFileTool(this.schema, this.process);

  final HarnessTool schema;
  final ControlledEvaluationProcess process;

  @override
  String get name => schema.name;

  @override
  String get description =>
      '${schema.description} '
      'Controlled evaluation limits: files at most 1 MiB, writes at most '
      '32 KiB, reads at most 200 lines/10 KiB, searches at most 2000 files.';
  @override
  Map<String, dynamic> get inputSchema {
    if (name != 'read') {
      return schema.inputSchema;
    }
    final original = schema.inputSchema;
    final props = Map<String, dynamic>.from(original['properties'] as Map);
    props['limit'] = {
      'type': 'integer',
      'description': 'Maximum lines (at most 200).',
      'default': 200,
    };
    return {...original, 'properties': props};
  }

  @override
  ToolApprovalTier get approvalTier => schema.approvalTier;
  @override
  bool get speculativeReadSafe => approvalTier == ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    // Arguments are bounded before encoding. In particular, a candidate cannot
    // smuggle an arbitrarily large write/edit payload into a process argv.
    try {
      final request = utf8.encode(jsonEncode({'op': name, 'args': args}));
      if (request.length > 48 * 1024) {
        return HarnessToolResult.error('Tool arguments exceed 48 KiB.');
      }
      final result = await process.execute(
        '/usr/bin/python3',
        ['-I', '-S', '-c', _adapter, base64Url.encode(request)],
        timeout: const Duration(seconds: 15),
        cancel: context.cancel,
      );
      if (result.timedOut) {
        return HarnessToolResult.error('$name timed out.');
      }
      if (result.exitCode != 0) {
        return HarnessToolResult.error(
          '$name failed inside the enclosure: '
          '${result.stderr.isEmpty ? 'process exit ${result.exitCode}' : result.stderr}',
        );
      }
      final response = jsonDecode(result.stdout);
      if (response is! Map ||
          response['text'] is! String ||
          response['ok'] is! bool) {
        return HarnessToolResult.error('$name returned an invalid response.');
      }
      return response['ok'] == true
          ? HarnessToolResult.success(response['text'] as String)
          : HarnessToolResult.error(response['text'] as String);
    } on Object catch (error) {
      return HarnessToolResult.error(
        '$name failed inside the enclosure: $error',
      );
    }
  }
}

// Limits apply BEFORE reads, including sparse files and files growing between
// stat and open. The sandbox policy (not path checking) enforces host isolation;
// realpath and lexical checks further confine operations to the attempt tree.
const _adapter = r'''
import base64, fnmatch, json, os, re, sys

MAX_FILE = 1024 * 1024
MAX_INPUT = 32 * 1024
MAX_FILES = 2000
MAX_OUTPUT = 10000
root = os.path.realpath(os.getcwd())
req = json.loads(base64.urlsafe_b64decode(sys.argv[1]))
op = req['op']
a = req['args']

class Rejected(Exception): pass

def fail(message): raise Rejected(message)
def field(obj, name):
    value = obj.get(name)
    if not isinstance(value, str) or not value:
        fail('Missing or invalid argument: ' + name)
    return value

def inside(path):
    raw = os.path.normpath(os.path.join(root, path))
    if os.path.commonpath((root, raw)) != root:
        fail('Path outside evaluation workspace: ' + path)
    cursor = root
    for part in os.path.relpath(raw, root).split(os.sep):
        cursor = os.path.join(cursor, part)
        if os.path.islink(cursor):
            fail('Symlink paths are unavailable in controlled file tools')
    resolved = os.path.realpath(raw)
    if os.path.commonpath((root, resolved)) != root:
        fail('Path outside evaluation workspace: ' + path)
    return raw, resolved

def protected(raw, resolved):
    for path in (raw, resolved):
        if os.path.commonpath((os.path.join(root, '.agents'), path)) == os.path.join(root, '.agents'):
            fail('Immutable evaluation skill assets')

def bounded_file(path):
    with open(path, 'rb') as f:
        data = f.read(MAX_FILE + 1)
    if len(data) > MAX_FILE: fail('File exceeds 1 MiB input limit')
    try: return data.decode('utf-8')
    except UnicodeDecodeError: fail('Cannot read binary file: ' + path)

def output(ok, text):
    data = json.dumps({'ok': ok, 'text': text}, ensure_ascii=True)
    if len(data.encode('utf-8')) > 14000:
        data = json.dumps({'ok': False, 'text': 'Tool output exceeds 14 KiB; narrow the request.'})
    sys.stdout.write(data)

def rel(path): return os.path.relpath(path, root).replace(os.sep, '/')

def walk(base):
    visited = 0
    for current, dirs, files in os.walk(base, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in ('.git','node_modules','.dart_tool','build','.fvm') and not os.path.islink(os.path.join(current,d)))
        for name in sorted(files):
            path = os.path.join(current, name)
            if os.path.islink(path): continue
            visited += 1
            if visited > MAX_FILES: fail('Search exceeds 2000 files; narrow the path.')
            yield path

def glob_regex(pattern):
    pieces = ['^']
    i = 0
    while i < len(pattern):
        if pattern.startswith('**/',i): pieces.append('(?:.*/)?'); i += 3
        elif pattern.startswith('**',i): pieces.append('.*'); i += 2
        elif pattern[i] == '*': pieces.append('[^/]*'); i += 1
        elif pattern[i] == '?': pieces.append('[^/]'); i += 1
        else: pieces.append(re.escape(pattern[i])); i += 1
    return re.compile(''.join(pieces) + '$')

try:
    if op == 'read':
        path = field(a,'path')
        raw,_ = inside(path)
        if not os.path.isfile(raw): fail('File not found: ' + path)
        text = bounded_file(raw)
        if '\x00' in text: fail('Cannot read binary file: ' + path)
        lines = text.split('\n')
        start, count = a.get('offset', 1), a.get('limit', 200)
        sel = a.get('sel')
        if isinstance(sel,str) and sel:
            match = re.fullmatch(r'(\d+)(?:-(\d+)|\+(\d+))?',sel)
            if match:
                start = int(match[1]); count = (int(match[2])-start+1 if match[2] else int(match[3]) if match[3] else 1)
        if not isinstance(start,int) or not isinstance(count,int): fail('Invalid read offset/limit')
        start = max(1,start); count = min(max(0,count),200)
        if start > len(lines):
            output(True,'(file has %d lines; offset %d is past the end)' % (len(lines),start-1))
        else:
            shown = []
            size = 0
            for index in range(start-1,min(len(lines),start-1+count)):
                line = '%d\t%s\n' % (index+1,lines[index])
                size += len(line.encode('utf-8'))
                if size > MAX_OUTPUT: break
                shown.append(line)
            if not shown: fail('Read window exceeds 10 KiB; use a narrower file or range.')
            last = start+len(shown)-1
            body = '[file %s lines=%d]\n%s' % (path,len(lines),''.join(shown).rstrip('\n'))
            if start > 1 or last < len(lines):
                body += '\n[showing lines %d-%d of %d; continue with offset=%d]' % (start,last,len(lines),last+1)
            output(True,body)
    elif op == 'write':
        path = field(a,'path'); content = a.get('content')
        if not isinstance(content,str): fail('Missing or invalid argument: content')
        if len(content.encode('utf-8')) > MAX_INPUT: fail('Write exceeds 32 KiB input limit')
        raw,resolved = inside(path); protected(raw,resolved)
        os.makedirs(os.path.dirname(raw),exist_ok=True)
        raw,resolved = inside(path); protected(raw,resolved)
        existed = os.path.isfile(raw)
        with open(raw,'w',encoding='utf-8') as f: f.write(content)
        output(True,'%s %s (%d lines).' % ('Updated' if existed else 'Created',path,content.count('\n')+1))
    elif op == 'edit':
        edits = a.get('edits', [a])
        if not isinstance(edits,list) or not edits: fail('No edits provided. Pass path/old_text/new_text or an `edits` array.')
        if len(edits)>32: fail('Too many edits (maximum 32)')
        buffers, names, counts = {}, {}, {}
        for edit in edits:
            if not isinstance(edit,dict): fail('Invalid edit')
            path = field(edit,'path'); old = field(edit,'old_text'); new = edit.get('new_text')
            if not isinstance(new,str): fail('Missing or invalid argument: new_text')
            raw,resolved = inside(path); protected(raw,resolved)
            if raw not in buffers:
                if not os.path.isfile(raw): fail('File not found: ' + path)
                buffers[raw] = bounded_file(raw); names[raw] = path; counts[raw] = 0
            found = buffers[raw].count(old)
            if not found: fail('old_text not found in %s. The file may have changed; read it again before editing.' % path)
            if found>1 and edit.get('replace_all') is not True:
                fail('old_text appears %d times in %s; it must be unique (or set replace_all).' % (found,path))
            buffers[raw] = buffers[raw].replace(old,new,-1 if edit.get('replace_all') is True else 1)
            if len(buffers[raw].encode('utf-8')) > MAX_FILE: fail('Edited file exceeds 1 MiB input limit')
            counts[raw] += 1
        # Re-check all targets immediately before writing (including symlink swaps).
        for path in buffers:
            raw,resolved = inside(path); protected(raw,resolved)
        for path,content in buffers.items():
            with open(path,'w',encoding='utf-8') as f: f.write(content)
        if len(buffers)==1:
            path = next(iter(buffers))
            output(True,'Edited %s (%d change%s).' % (names[path],counts[path],'' if counts[path]==1 else 's'))
        else:
            output(True,'Edited %d files: %s.' % (len(buffers),', '.join('%s (%d)' % (names[p],counts[p]) for p in buffers)))
    elif op in ('find','search'):
        pattern = field(a,'pattern')
        path = a.get('path','.')
        if not isinstance(path,str): fail('Missing or invalid argument: path')
        base,_ = inside(path)
        if not os.path.isdir(base): fail('Directory not found: ' + path)
        matches = []
        if op == 'find':
            regex = glob_regex(pattern)
            for item in walk(base):
                relative = os.path.relpath(item,base).replace(os.sep,'/')
                if regex.match(relative): matches.append((os.stat(item).st_mtime,relative))
            matches.sort(key=lambda pair:-pair[0]); results = [name for _,name in matches[:200]]
            output(True,('No files match %s.' % pattern) if not matches else '\n'.join(results) + ('\n\n(%d total; showing first 200)' % len(matches) if len(matches)>200 else ''))
        else:
            regex = re.compile(pattern)
            filt = a.get('glob','*')
            if not isinstance(filt,str): fail('Invalid glob filter')
            for item in walk(base):
                if not fnmatch.fnmatchcase(os.path.basename(item),filt): continue
                if os.stat(item).st_size>MAX_FILE: continue
                try: text = bounded_file(item)
                except (Rejected,UnicodeDecodeError): continue
                if '\x00' in text: continue
                for number,line in enumerate(text.splitlines(),1):
                    if regex.search(line):
                        result = '%s:%d:%s' % (rel(item),number,line)
                        if len(result.encode('utf-8'))>MAX_OUTPUT: result = result[:2000]+' [line truncated]'
                        matches.append(result)
                        if len(matches)>200: break
                if len(matches)>200: break
            output(True,('No matches for /%s/.' % pattern) if not matches else '\n'.join(matches[:200]) + ('\n\n(showing first 200 matches)' if len(matches)>200 else ''))
    else: fail('Unsupported tool operation')
except (Rejected, OSError, ValueError, re.error) as error:
    output(False,str(error)[:1000])
''';
