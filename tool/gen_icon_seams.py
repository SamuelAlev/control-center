#!/usr/bin/env python3
"""Regenerate the icon seam files (AppIcons/CcIcons) from the mapping below.

There is no package:phosphoricons_flutter dependency: its generated style
classes hold ~1530 static const fields each and linking one stack-overflows
Flutter web's dev compiler (DDC), so nothing could import it anyway — and its
pubspec declared all six style fonts, five of which we never reference and
could not opt out of. cc_ui vendors the one Phosphor Regular TTF instead
(packages/cc_ui/fonts/Phosphor-Regular.ttf) and each consumer declares raw
IconData codepoints against it. This script owns those three tables.

To swap icon libraries again: replace MAPPING, FONT_FAMILY and FONT_PACKAGE,
swap the vendored TTF + the cc_ui pubspec `fonts:` entry, then re-run. Never
edit the generated files by hand.

Usage: python3 tool/gen_icon_seams.py   (run from the repo root)
"""

FONT_FAMILY = 'PhosphorRegular'
FONT_PACKAGE = 'cc_ui'

# member name: (phosphoricons_flutter PhosphorIconsRegular name, codepoint).
# Codepoints verified against phosphoricons_flutter 1.0.0
# (lib/src/phosphor_icons_regular.dart).
MAPPING = {
    'activity': ('activity', 0xe000),
    'alertCircle': ('warningCircle', 0xe4e2),
    'alertTriangle': ('warning', 0xe4e0),
    'alignJustify': ('textAlignJustify', 0xe482),
    'appWindow': ('appWindow', 0xe5da),
    'archive': ('archive', 0xe00c),
    'archiveRestore': ('archiveBox', 0xe00e),
    'arrowDown': ('arrowDown', 0xe03e),
    'arrowLeft': ('arrowLeft', 0xe058),
    'arrowRight': ('arrowRight', 0xe06c),
    'arrowUp': ('arrowUp', 0xe08e),
    'arrowUpRight': ('arrowUpRight', 0xe092),
    'atSign': ('at', 0xe0ac),
    'audioLines': ('waveform', 0xe802),
    'audioWaveform': ('waveform', 0xe802),
    'award': ('medal', 0xe320),
    'ban': ('minusCircle', 0xe32c),
    'barChart2': ('chartBar', 0xe150),
    'bell': ('bell', 0xe0ce),
    'bellOff': ('bellSlash', 0xe0d4),
    'bold': ('textB', 0xe5be),
    'bookMarked': ('bookmarks', 0xe0ec),
    'bookmark': ('bookmarkSimple', 0xe0ea),
    'bookmarkCheck': ('bookmarkSimple', 0xe0ea),
    'bot': ('robot', 0xe762),
    'box': ('package', 0xe390),
    'boxes': ('package', 0xe390),
    'brain': ('brain', 0xe74e),
    'bug': ('bug', 0xe5f4),
    'building2': ('building', 0xe100),
    'cable': ('plugsConnected', 0xeb5a),
    'calculator': ('calculator', 0xe538),
    'calendar': ('calendar', 0xe108),
    'calendarClock': ('calendar', 0xe108),
    'calendarDays': ('calendar', 0xe108),
    'calendarPlus': ('calendarPlus', 0xe714),
    'calendarX': ('calendarX', 0xe10c),
    'caseSensitive': ('textAa', 0xe6ee),
    'chartColumn': ('chartBar', 0xe150),
    'chatDashed': ('chat', 0xe15c),
    'check': ('check', 0xe182),
    'checkCheck': ('checks', 0xe53a),
    'checkCircle': ('checkCircle', 0xe184),
    'checkCircle2': ('checkCircle', 0xe184),
    'checkSquare': ('checkSquare', 0xe186),
    'chevronDown': ('caretDown', 0xe136),
    'chevronLeft': ('caretLeft', 0xe138),
    'chevronRight': ('caretRight', 0xe13a),
    'chevronUp': ('caretUp', 0xe13c),
    'chevronsDown': ('caretDoubleDown', 0xe126),
    'chevronsDownUp': ('arrowsInLineVertical', 0xe532),
    'chevronsUpDown': ('caretUpDown', 0xe140),
    'circle': ('circle', 0xe18a),
    'circleAlert': ('warningCircle', 0xe4e2),
    'circleCheck': ('checkCircle', 0xe184),
    'circleCheckBig': ('checkCircle', 0xe184),
    'circleDashed': ('circleDashed', 0xe602),
    'circleDot': ('record', 0xe3ee),
    'circleHelp': ('question', 0xe3e8),
    'circlePlay': ('playCircle', 0xe3d2),
    'circleSlash': ('minusCircle', 0xe32c),
    'circleStop': ('stopCircle', 0xe46e),
    'circleX': ('xCircle', 0xe4f8),
    'clapperboard': ('filmSlate', 0xe8c2),
    'clipboard': ('clipboard', 0xe196),
    'clock': ('clock', 0xe19a),
    'clock3': ('clock', 0xe19a),
    'cloud': ('cloud', 0xe1aa),
    'cloudOff': ('cloudSlash', 0xe1b6),
    'code': ('code', 0xe1bc),
    'columns': ('columns', 0xe546),
    'columns3': ('columns', 0xe546),
    'command': ('command', 0xe1c4),
    'compass': ('compass', 0xe1c8),
    'cookie': ('cookie', 0xe6ca),
    'copy': ('copy', 0xe1ca),
    'cornerDownLeft': ('arrowElbowDownLeft', 0xe044),
    'cornerLeftDown': ('arrowElbowLeftDown', 0xe04a),
    'cornerLeftUp': ('arrowElbowLeftUp', 0xe04c),
    'cpu': ('cpu', 0xe610),
    'crosshair': ('crosshair', 0xe1d6),
    'diff': ('plusMinus', 0xe3d8),
    'dollarSign': ('currencyDollar', 0xe550),
    'dot': ('dot', 0xecde),
    'download': ('downloadSimple', 0xe20c),
    'ellipsis': ('dotsThree', 0xe1fe),
    'externalLink': ('arrowSquareOut', 0xe5de),
    'eye': ('eye', 0xe220),
    'eyeOff': ('eyeSlash', 0xe224),
    'factory': ('factory', 0xe760),
    'feather': ('feather', 0xe9c0),
    'file': ('file', 0xe230),
    'fileCode': ('fileCode', 0xe914),
    'fileDiff': ('gitDiff', 0xe27c),
    'fileEdit': ('notePencil', 0xe34c),
    'filePen': ('notePencil', 0xe34c),
    'filePlus': ('filePlus', 0xe236),
    'fileQuestion': ('fileDashed', 0xe704),
    'fileText': ('fileText', 0xe23a),
    'files': ('files', 0xe710),
    'filterX': ('funnelX', 0xe26c),
    'flag': ('flag', 0xe244),
    'flame': ('flame', 0xe624),
    'flaskConical': ('flask', 0xe79e),
    'focus': ('frameCorners', 0xe626),
    'folder': ('folder', 0xe24a),
    'folderGit': ('folder', 0xe24a),
    'folderGit2': ('folder', 0xe24a),
    'folderOpen': ('folderOpen', 0xe256),
    'folderTree': ('folders', 0xe260),
    'gauge': ('gauge', 0xe628),
    'gem': ('diamond', 0xe1ec),
    'gitBranch': ('gitBranch', 0xe278),
    'gitCommit': ('gitCommit', 0xe27a),
    'gitCommitHorizontal': ('gitCommit', 0xe27a),
    'gitCompareArrows': ('gitDiff', 0xe27c),
    'gitFork': ('gitFork', 0xe27e),
    'gitMerge': ('gitMerge', 0xe280),
    'gitPullRequest': ('gitPullRequest', 0xe282),
    'gitPullRequestArrow': ('gitPullRequest', 0xe282),
    # Phosphor Regular has no draft/closed PR variants (Lucide does). Map to
    # distinct glyphs so status is never colour-only: dashed = not ready, X =
    # closed without merge. Open stays gitPullRequest; merged stays gitMerge.
    'gitPullRequestClosed': ('xCircle', 0xe4f8),
    'gitPullRequestCreate': ('gitPullRequest', 0xe282),
    'gitPullRequestCreateArrow': ('gitPullRequest', 0xe282),
    'gitPullRequestDraft': ('circleDashed', 0xe602),
    'globe': ('globe', 0xe288),
    'gripVertical': ('dotsSixVertical', 0xeae2),
    'hash': ('hash', 0xe2a2),
    'heading': ('textH', 0xe6ba),
    'house': ('house', 0xe2c2),
    'image': ('image', 0xe2ca),
    'imageOff': ('imageBroken', 0xe7a8),
    'inbox': ('tray', 0xe4aa),
    'info': ('info', 0xe2ce),
    'italic': ('textItalic', 0xe5c0),
    'keyRound': ('key', 0xe2d6),
    'keyboard': ('keyboard', 0xe2d8),
    'languages': ('translate', 0xe4a2),
    'layers': ('stack', 0xe466),
    'layoutDashboard': ('squaresFour', 0xe464),
    'layoutGrid': ('gridFour', 0xe296),
    'layoutTemplate': ('layout', 0xe6d6),
    'lightbulb': ('lightbulb', 0xe2dc),
    'link': ('link', 0xe2e2),
    'list': ('list', 0xe2f0),
    'listChecks': ('listChecks', 0xeadc),
    'listFilter': ('funnel', 0xe266),
    'listTodo': ('listChecks', 0xeadc),
    'loader': ('circleNotch', 0xeb44),
    'loaderCircle': ('circleNotch', 0xeb44),
    'lock': ('lock', 0xe2fa),
    'logOut': ('signOut', 0xe42a),
    'mapPin': ('mapPin', 0xe316),
    'maximize2': ('cornersOut', 0xe1d0),
    'medal': ('medal', 0xe320),
    'menu': ('list', 0xe2f0),
    'messageCircle': ('chatCircle', 0xe168),
    'messageCircleQuestion': ('chatCircle', 0xe168),
    'messageSquare': ('chat', 0xe15c),
    'messageSquareCode': ('chat', 0xe15c),
    'messageSquareDashed': ('chat', 0xe15c),
    'messageSquarePlus': ('chat', 0xe15c),
    'messageSquareText': ('chatText', 0xe17a),
    'messagesSquare': ('chats', 0xe17c),
    'mic': ('microphone', 0xe326),
    'micOff': ('microphoneSlash', 0xe328),
    'minus': ('minus', 0xe32a),
    'minusCircle': ('minusCircle', 0xe32c),
    'monitor': ('monitor', 0xe32e),
    'moon': ('moon', 0xe330),
    'moonStar': ('moonStars', 0xe58e),
    'moreHorizontal': ('dotsThree', 0xe1fe),
    'move': ('arrowsOutCardinal', 0xe0a4),
    'network': ('treeStructure', 0xe67c),
    'newspaper': ('newspaper', 0xe344),
    'notebook': ('notebook', 0xe34e),
    'notebookPen': ('notebook', 0xe34e),
    'notebookText': ('notebook', 0xe34e),
    'octagonAlert': ('warningOctagon', 0xe4e4),
    'paintbrushVertical': ('paintBrush', 0xe6f0),
    'palette': ('palette', 0xe6c8),
    'panelLeft': ('sidebar', 0xeab6),
    'panelLeftClose': ('sidebar', 0xeab6),
    'panelLeftOpen': ('sidebar', 0xeab6),
    'panelRight': ('sidebarSimple', 0xec24),
    'pause': ('pause', 0xe39e),
    'pauseCircle': ('pauseCircle', 0xe3a0),
    'pencil': ('pencilSimple', 0xe3b4),
    'pencilRuler': ('pencilRuler', 0xe906),
    'pictureInPicture2': ('pictureInPicture', 0xe64c),
    'pin': ('pushPin', 0xe3e2),
    'pinOff': ('pushPinSlash', 0xe3e4),
    'play': ('play', 0xe3d0),
    'plug': ('plug', 0xe946),
    'plus': ('plus', 0xe3d4),
    'power': ('power', 0xe3da),
    'puzzle': ('puzzlePiece', 0xe596),
    'quote': ('quotes', 0xe660),
    'radio': ('radio', 0xe77e),
    'refreshCw': ('arrowClockwise', 0xe036),
    'regex': ('asterisk', 0xe0aa),
    'repeat': ('repeat', 0xe3f6),
    'reply': ('arrowBendUpLeft', 0xe024),
    'rocket': ('rocket', 0xe3fc),
    'rotateCcw': ('arrowCounterClockwise', 0xe038),
    'rotateCw': ('arrowClockwise', 0xe036),
    'rss': ('rss', 0xe400),
    'save': ('floppyDisk', 0xe248),
    'scale': ('scales', 0xe750),
    'scanEye': ('eye', 0xe220),
    'scanLine': ('scan', 0xebb6),
    'scanSearch': ('scan', 0xebb6),
    'scrollText': ('scroll', 0xeb7a),
    'search': ('magnifyingGlass', 0xe30c),
    'searchX': ('magnifyingGlassMinus', 0xe30e),
    'send': ('paperPlaneRight', 0xe396),
    'settings': ('gear', 0xe270),
    'share2': ('shareNetwork', 0xe408),
    'shield': ('shield', 0xe40a),
    'shieldAlert': ('shieldWarning', 0xe412),
    'shieldCheck': ('shieldCheck', 0xe40c),
    'shieldOff': ('shieldSlash', 0xe410),
    'signalHigh': ('cellSignalHigh', 0xe144),
    'skull': ('skull', 0xe916),
    'slidersHorizontal': ('slidersHorizontal', 0xe434),
    'smartphone': ('deviceMobile', 0xe1e0),
    'smile': ('smiley', 0xe436),
    'sparkles': ('sparkle', 0xe6a2),
    'square': ('square', 0xe45e),
    'squareCheck': ('checkSquare', 0xe186),
    'squareCheckBig': ('checkSquare', 0xe186),
    'squarePen': ('pencilSimpleLine', 0xebc6),
    'star': ('star', 0xe46a),
    'sun': ('sun', 0xe472),
    'tag': ('tag', 0xe478),
    'target': ('target', 0xe47c),
    'terminal': ('terminal', 0xe47e),
    'thumbsDown': ('thumbsDown', 0xe48c),
    'thumbsUp': ('thumbsUp', 0xe48e),
    'ticket': ('ticket', 0xe490),
    'ticketCheck': ('ticket', 0xe490),
    'toggleLeft': ('toggleLeft', 0xe674),
    'trash2': ('trash', 0xe4a6),
    'trendingUp': ('trendUp', 0xe4ae),
    'triangleAlert': ('warning', 0xe4e0),
    'trophy': ('trophy', 0xe67e),
    'type': ('textT', 0xe48a),
    'undo2': ('arrowUUpLeft', 0xe08a),
    'unlink': ('linkBreak', 0xe2e4),
    'unplug': ('plugs', 0xeb56),
    'upload': ('uploadSimple', 0xe4c0),
    'user': ('user', 0xe4c2),
    'userCheck': ('userCheck', 0xeafa),
    'userCog': ('userGear', 0xe4cc),
    'userMinus': ('userMinus', 0xe4ce),
    'userPlus': ('userPlus', 0xe4d0),
    'userRound': ('userCircle', 0xe4c4),
    'users': ('users', 0xe4d6),
    'video': ('videoCamera', 0xe4da),
    'volume2': ('speakerHigh', 0xe44a),
    'volumeOff': ('speakerSlash', 0xe45a),
    'wand': ('magicWand', 0xe6b6),
    'wifiOff': ('wifiSlash', 0xe4f2),
    'workflow': ('flowArrow', 0xe6ec),
    'wrapText': ('textIndent', 0xea1e),
    'wrench': ('wrench', 0xe5d4),
    'x': ('x', 0xe4f6),
    'xCircle': ('xCircle', 0xe4f8),
    'zap': ('lightning', 0xe2de),
    'zapOff': ('lightningSlash', 0xe2e0),
}

ROOT_MEMBERS = {
    'activity', 'alertCircle', 'alertTriangle', 'alignJustify', 'appWindow', 'archive',
    'archiveRestore', 'arrowDown', 'arrowLeft', 'arrowRight', 'arrowUp', 'arrowUpRight',
    'atSign', 'audioLines', 'audioWaveform', 'award', 'ban', 'barChart2',
    'bell', 'bellOff', 'bold', 'bookMarked', 'bookmark', 'bookmarkCheck',
    'bot', 'box', 'boxes', 'brain', 'bug', 'building2',
    'cable', 'calculator', 'calendar', 'calendarClock', 'calendarDays', 'calendarPlus',
    'calendarX', 'caseSensitive', 'chartColumn', 'check', 'checkCheck', 'checkCircle',
    'checkCircle2', 'checkSquare', 'chevronDown', 'chevronLeft', 'chevronRight', 'chevronUp',
    'chevronsDown', 'chevronsDownUp', 'chevronsUpDown', 'circle', 'circleAlert', 'circleCheck',
    'circleCheckBig', 'circleDashed', 'circleDot', 'circleHelp', 'circlePlay', 'circleSlash',
    'circleStop', 'circleX', 'clapperboard', 'clipboard', 'clock', 'clock3',
    'cloud', 'cloudOff', 'code', 'columns', 'columns3', 'command',
    'compass', 'cookie', 'copy', 'cornerDownLeft', 'cornerLeftDown', 'cornerLeftUp',
    'cpu', 'crosshair', 'diff', 'dollarSign', 'dot', 'download',
    'ellipsis', 'externalLink', 'eye', 'eyeOff', 'factory', 'file',
    'fileCode', 'fileDiff', 'fileEdit', 'filePen', 'filePlus', 'fileQuestion',
    'fileText', 'files', 'filterX', 'flag', 'flame', 'focus',
    'folder', 'folderGit', 'folderGit2', 'folderOpen', 'folderTree', 'gauge',
    'gem', 'gitBranch', 'gitCommit', 'gitCommitHorizontal', 'gitCompareArrows', 'gitFork',
    'gitMerge', 'gitPullRequest', 'gitPullRequestArrow', 'gitPullRequestClosed', 'gitPullRequestCreate', 'gitPullRequestDraft',
    'globe', 'gripVertical', 'hash', 'heading', 'image', 'imageOff',
    'inbox', 'info', 'italic', 'keyRound', 'keyboard', 'languages',
    'layers', 'layoutDashboard', 'layoutGrid', 'layoutTemplate', 'lightbulb', 'link', 'list',
    'listChecks', 'listFilter', 'listTodo', 'loader', 'loaderCircle', 'lock',
    'logOut', 'mapPin', 'maximize2', 'medal', 'menu', 'messageCircle',
    'messageCircleQuestion', 'messageSquare', 'messageSquareCode', 'messageSquareDashed', 'messageSquarePlus', 'messageSquareText',
    'messagesSquare', 'mic', 'micOff', 'minus', 'minusCircle', 'monitor',
    'moon', 'moonStar', 'moreHorizontal', 'move', 'network', 'newspaper',
    'notebook', 'notebookPen', 'notebookText', 'octagonAlert', 'paintbrushVertical', 'palette',
    'panelLeft',
    'panelLeftClose', 'panelLeftOpen', 'panelRight', 'pause', 'pauseCircle', 'pencil',
    'pictureInPicture2', 'pin', 'pinOff', 'play', 'plug', 'plus',
    'power', 'puzzle', 'quote', 'radio', 'refreshCw', 'regex',
    'repeat', 'reply', 'rocket', 'rotateCcw', 'rotateCw', 'rss',
    'save', 'scale', 'scanEye', 'scanSearch', 'scrollText', 'search',
    'searchX', 'send', 'settings', 'share2', 'shield', 'shieldAlert',
    'shieldCheck', 'shieldOff', 'signalHigh', 'skull', 'slidersHorizontal', 'smartphone',
    'smile', 'sparkles', 'square', 'squareCheck', 'squareCheckBig', 'squarePen',
    'star', 'sun', 'tag', 'target', 'terminal', 'thumbsDown',
    'thumbsUp', 'ticket', 'ticketCheck', 'toggleLeft', 'trash2', 'trendingUp',
    'triangleAlert', 'trophy', 'type', 'undo2', 'unlink', 'unplug',
    'upload', 'user', 'userCheck', 'userCog', 'userMinus', 'userPlus',
    'userRound', 'users', 'video', 'volume2', 'volumeOff', 'wand',
    'workflow', 'wrapText', 'wrench', 'x', 'xCircle', 'zap',
    'zapOff',
}

CCUI_MEMBERS = {
    'activity', 'bell', 'bookmark', 'bot', 'boxes', 'calendarClock',
    'calendarX', 'check', 'chevronDown', 'chevronRight', 'circleCheck', 'circleDashed',
    'circleX', 'clock', 'code', 'copy', 'cornerLeftUp', 'eye',
    'eyeOff', 'feather', 'fileCode', 'fileDiff', 'flaskConical', 'folder',
    'folderGit', 'folderGit2', 'folderOpen', 'folderTree', 'gitBranch', 'gitMerge',
    'gitPullRequest', 'gitPullRequestArrow', 'gitPullRequestClosed', 'gitPullRequestCreateArrow', 'gitPullRequestDraft', 'house',
    'inbox', 'info', 'keyRound', 'layers', 'layoutDashboard', 'listFilter',
    'listTodo', 'lock', 'messageSquare', 'minus', 'palette', 'pencil',
    'pencilRuler', 'play', 'plus', 'refreshCw', 'rocket', 'search',
    'settings', 'sparkles', 'star', 'tag', 'trash2', 'triangleAlert',
    'user', 'users', 'workflow', 'x', 'zap',
}

REMOTE_MEMBERS = {
    'arrowDown', 'arrowLeft', 'bookmark', 'bookmarkCheck', 'bot', 'check',
    'chevronDown', 'chevronRight', 'chevronsDown', 'circleCheck', 'externalLink', 'globe',
    'hash', 'languages', 'layers', 'loader', 'logOut', 'messageCircle',
    'minus', 'monitor', 'moon', 'newspaper', 'palette', 'refreshCw',
    'scanLine', 'send', 'settings', 'sparkles', 'sun', 'ticket',
    'triangleAlert', 'user', 'userCheck', 'wifiOff', 'x',
}

HEADER = """// GENERATED BY tool/gen_icon_seams.py — DO NOT EDIT.
// The icon constants below are self-documenting (name == glyph); per-field doc
// comments would be pure noise.
// ignore_for_file: public_member_api_docs
import 'package:flutter/widgets.dart';

"""

ROOT_DOC = """/// Web-safe Phosphor icon set for the whole application.
///
/// The glyphs resolve against the Phosphor Regular font vendored by cc_ui
/// (`packages/cc_ui/fonts/Phosphor-Regular.ttf`), not an icon package. An
/// icon package exposes each style as a class of ~1530 `static const IconData`
/// fields; on Flutter web the dev compiler (DDC) lazily links a library the
/// first time one of its members is accessed and linking that giant library
/// overflows the JS stack and crashes with a `StackOverflowError` before the
/// first frame renders (so `flutter run -d chrome` breaks even though a
/// dart2js release build is fine).
///
/// Declaring only the glyphs the app actually uses also keeps the icon
/// tree-shaker effective: the shipped font is a ~52 KB subset of the 489 KB
/// original. Generated by `tool/gen_icon_seams.py` — edit the mapping there,
/// never this file.
///
/// A ratchet in `test/core/lib_boundary_test.dart` forbids importing any
/// icon package into `lib/`.
"""

CCUI_DOC = """/// The Phosphor glyphs cc_ui's own components (and the gallery / cc_ui
/// tests) need.
///
/// cc_ui owns the Phosphor Regular font itself (`fonts/Phosphor-Regular.ttf`)
/// and deliberately depends on no icon package. Such a package exposes each
/// style as a class of ~1530 `static const IconData` fields; on Flutter web
/// the dev compiler (DDC) links a library the first time any member is
/// touched and linking that giant class overflows the JS stack — crashing
/// `flutter run -d chrome` before the first frame. Since cc_ui is the shared
/// design system, that would break the web build for every consumer.
/// Declaring only the codepoints used avoids the link and lets the icon
/// tree-shaker subset the font down to what is actually rendered.
///
/// Generated by `tool/gen_icon_seams.py` — edit the mapping there, never
/// this file. cc_ui is purist — built on `package:flutter/widgets.dart`
/// only — and this keeps it web-safe too.
"""

REMOTE_DOC = """/// Icons used by cc_remote, referenced directly against the Phosphor Regular
/// font vendored by cc_ui (`packages/cc_ui/fonts/Phosphor-Regular.ttf`).
///
/// We deliberately depend on no icon package. Such a package exposes each
/// style as a class of ~1530 `static const IconData` fields; on Flutter web
/// the dev compiler (DDC) lazily links a library the first time one of its
/// members is accessed and linking that giant library overflows the JS stack
/// — crashing with a `StackOverflowError` before the first screen can render.
/// cc_remote is a web PWA, so this is fatal.
///
/// Generated by `tool/gen_icon_seams.py` — edit the mapping there, never
/// this file.
"""

FILES = [
    ('lib/shared/icons/app_icons.dart', 'AppIcons', ROOT_MEMBERS, ROOT_DOC),
    ('packages/cc_ui/lib/src/components/cc_icons.dart', 'CcIcons', CCUI_MEMBERS, CCUI_DOC),
    ('apps/cc_remote/lib/app_icons.dart', 'AppIcons', REMOTE_MEMBERS, REMOTE_DOC),
]


def emit(path, class_name, members, doc):
    lines = [HEADER, doc, '@staticIconProvider\n']
    lines.append(f'abstract final class {class_name} {{\n')
    lines.append(f"  static const String _family = '{FONT_FAMILY}';\n")
    lines.append(f"  static const String _package = '{FONT_PACKAGE}';\n\n")
    for name in sorted(members):
        phosphor_name, codepoint = MAPPING[name]
        lines.append(f'  static const IconData {name} = IconData(\n')
        lines.append(f'    {codepoint:#x},\n')
        lines.append('    fontFamily: _family,\n')
        lines.append('    fontPackage: _package,\n')
        lines.append('  );\n')
    lines.append('}\n')
    with open(path, 'w') as f:
        f.write(''.join(lines))
    print(f'wrote {path} ({len(members)} icons)')


if __name__ == '__main__':
    for path, class_name, members, doc in FILES:
        missing = members - MAPPING.keys()
        if missing:
            raise SystemExit(f'{path}: no mapping for {sorted(missing)}')
        emit(path, class_name, members, doc)
