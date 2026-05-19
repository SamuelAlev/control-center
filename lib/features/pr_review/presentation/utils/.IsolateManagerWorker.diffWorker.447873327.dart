import 'diff_worker_core.dart';
import 'package:isolate_manager/isolate_manager.dart';

main() {
  IsolateManagerFunction.customWorkerFunction(diffWorker);
}