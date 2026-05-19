// ignore_for_file: camel_case_types, non_constant_identifier_names
// ignore_for_file: public_member_api_docs, avoid_private_typedef_functions
import 'dart:ffi';

/// Minimal Dart-FFI bindings for the tree-sitter C runtime (`libtree-sitter`).
///
/// Hand-rolled rather than ffigen-generated to avoid an LLVM build-time
/// dependency and to keep the surface to exactly the symbols the indexer needs
/// (parser + query API). Struct layouts match `tree_sitter/api.h`. The grammar
/// entrypoint (`tree_sitter_<lang>`) lives in a separate grammar library and is
/// looked up by [TreeSitterLanguageLookup].

// --- Opaque handles -------------------------------------------------------

final class TSParser extends Opaque {}

final class TSTree extends Opaque {}

final class TSLanguage extends Opaque {}

final class TSQuery extends Opaque {}

final class TSQueryCursor extends Opaque {}

// --- By-value structs -----------------------------------------------------

/// `typedef struct { uint32_t row; uint32_t column; } TSPoint;`
final class TSPoint extends Struct {
  @Uint32()
  external int row;
  @Uint32()
  external int column;
}

/// `typedef struct { uint32_t context[4]; const void *id; const TSTree *tree;
/// } TSNode;`
final class TSNode extends Struct {
  @Array(4)
  external Array<Uint32> context;
  external Pointer<Void> id;
  external Pointer<TSTree> tree;
}

/// `typedef struct { TSNode node; uint32_t index; } TSQueryCapture;`
final class TSQueryCapture extends Struct {
  external TSNode node;
  @Uint32()
  external int index;
}

/// `typedef struct { uint32_t id; uint16_t pattern_index; uint16_t
/// capture_count; const TSQueryCapture *captures; } TSQueryMatch;`
final class TSQueryMatch extends Struct {
  @Uint32()
  external int id;
  @Uint16()
  external int patternIndex;
  @Uint16()
  external int captureCount;
  external Pointer<TSQueryCapture> captures;
}

// --- Native function typedefs --------------------------------------------

typedef _ParserNewNative = Pointer<TSParser> Function();
typedef _ParserDeleteNative = Void Function(Pointer<TSParser>);
typedef _ParserSetLanguageNative =
    Bool Function(Pointer<TSParser>, Pointer<TSLanguage>);
typedef _ParserParseStringNative =
    Pointer<TSTree> Function(
      Pointer<TSParser>,
      Pointer<TSTree>,
      Pointer<Char>,
      Uint32,
    );
typedef _TreeDeleteNative = Void Function(Pointer<TSTree>);
typedef _TreeRootNodeNative = TSNode Function(Pointer<TSTree>);
typedef _NodeByteNative = Uint32 Function(TSNode);
typedef _NodePointNative = TSPoint Function(TSNode);
typedef _QueryNewNative =
    Pointer<TSQuery> Function(
      Pointer<TSLanguage>,
      Pointer<Char>,
      Uint32,
      Pointer<Uint32>,
      Pointer<Uint32>,
    );
typedef _QueryDeleteNative = Void Function(Pointer<TSQuery>);
typedef _QueryCursorNewNative = Pointer<TSQueryCursor> Function();
typedef _QueryCursorDeleteNative = Void Function(Pointer<TSQueryCursor>);
typedef _QueryCursorExecNative =
    Void Function(Pointer<TSQueryCursor>, Pointer<TSQuery>, TSNode);
typedef _QueryCursorNextMatchNative =
    Bool Function(Pointer<TSQueryCursor>, Pointer<TSQueryMatch>);
typedef _QueryCaptureNameForIdNative =
    Pointer<Char> Function(Pointer<TSQuery>, Uint32, Pointer<Uint32>);

// --- Dart function typedefs ----------------------------------------------

typedef ParserNew = Pointer<TSParser> Function();
typedef ParserDelete = void Function(Pointer<TSParser>);
typedef ParserSetLanguage = bool Function(Pointer<TSParser>, Pointer<TSLanguage>);
typedef ParserParseString =
    Pointer<TSTree> Function(
      Pointer<TSParser>,
      Pointer<TSTree>,
      Pointer<Char>,
      int,
    );
typedef TreeDelete = void Function(Pointer<TSTree>);
typedef TreeRootNode = TSNode Function(Pointer<TSTree>);
typedef NodeByte = int Function(TSNode);
typedef NodePoint = TSPoint Function(TSNode);
typedef QueryNew =
    Pointer<TSQuery> Function(
      Pointer<TSLanguage>,
      Pointer<Char>,
      int,
      Pointer<Uint32>,
      Pointer<Uint32>,
    );
typedef QueryDelete = void Function(Pointer<TSQuery>);
typedef QueryCursorNew = Pointer<TSQueryCursor> Function();
typedef QueryCursorDelete = void Function(Pointer<TSQueryCursor>);
typedef QueryCursorExec =
    void Function(Pointer<TSQueryCursor>, Pointer<TSQuery>, TSNode);
typedef QueryCursorNextMatch =
    bool Function(Pointer<TSQueryCursor>, Pointer<TSQueryMatch>);
typedef QueryCaptureNameForId =
    Pointer<Char> Function(Pointer<TSQuery>, int, Pointer<Uint32>);

/// Looks up a grammar's `tree_sitter_<lang>` entrypoint, returning a
/// `TSLanguage*`.
typedef TreeSitterLanguageLookup = Pointer<TSLanguage> Function();

/// Resolved function pointers for the tree-sitter runtime, bound from a loaded
/// `libtree-sitter` dynamic library.
class TreeSitterBindings {
  TreeSitterBindings(DynamicLibrary runtime)
    : parserNew = runtime
          .lookupFunction<_ParserNewNative, ParserNew>('ts_parser_new'),
      parserDelete = runtime
          .lookupFunction<_ParserDeleteNative, ParserDelete>(
            'ts_parser_delete',
          ),
      parserSetLanguage = runtime
          .lookupFunction<_ParserSetLanguageNative, ParserSetLanguage>(
            'ts_parser_set_language',
          ),
      parserParseString = runtime
          .lookupFunction<_ParserParseStringNative, ParserParseString>(
            'ts_parser_parse_string',
          ),
      treeDelete = runtime
          .lookupFunction<_TreeDeleteNative, TreeDelete>('ts_tree_delete'),
      treeRootNode = runtime
          .lookupFunction<_TreeRootNodeNative, TreeRootNode>(
            'ts_tree_root_node',
          ),
      nodeStartByte = runtime
          .lookupFunction<_NodeByteNative, NodeByte>('ts_node_start_byte'),
      nodeEndByte = runtime
          .lookupFunction<_NodeByteNative, NodeByte>('ts_node_end_byte'),
      nodeStartPoint = runtime
          .lookupFunction<_NodePointNative, NodePoint>('ts_node_start_point'),
      nodeEndPoint = runtime
          .lookupFunction<_NodePointNative, NodePoint>('ts_node_end_point'),
      queryNew = runtime
          .lookupFunction<_QueryNewNative, QueryNew>('ts_query_new'),
      queryDelete = runtime
          .lookupFunction<_QueryDeleteNative, QueryDelete>('ts_query_delete'),
      queryCursorNew = runtime
          .lookupFunction<_QueryCursorNewNative, QueryCursorNew>(
            'ts_query_cursor_new',
          ),
      queryCursorDelete = runtime
          .lookupFunction<_QueryCursorDeleteNative, QueryCursorDelete>(
            'ts_query_cursor_delete',
          ),
      queryCursorExec = runtime
          .lookupFunction<_QueryCursorExecNative, QueryCursorExec>(
            'ts_query_cursor_exec',
          ),
      queryCursorNextMatch = runtime
          .lookupFunction<_QueryCursorNextMatchNative, QueryCursorNextMatch>(
            'ts_query_cursor_next_match',
          ),
      queryCaptureNameForId = runtime
          .lookupFunction<_QueryCaptureNameForIdNative, QueryCaptureNameForId>(
            'ts_query_capture_name_for_id',
          );

  final ParserNew parserNew;
  final ParserDelete parserDelete;
  final ParserSetLanguage parserSetLanguage;
  final ParserParseString parserParseString;
  final TreeDelete treeDelete;
  final TreeRootNode treeRootNode;
  final NodeByte nodeStartByte;
  final NodeByte nodeEndByte;
  final NodePoint nodeStartPoint;
  final NodePoint nodeEndPoint;
  final QueryNew queryNew;
  final QueryDelete queryDelete;
  final QueryCursorNew queryCursorNew;
  final QueryCursorDelete queryCursorDelete;
  final QueryCursorExec queryCursorExec;
  final QueryCursorNextMatch queryCursorNextMatch;
  final QueryCaptureNameForId queryCaptureNameForId;
}
