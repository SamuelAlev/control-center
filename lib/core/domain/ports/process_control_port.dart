abstract interface class ProcessControlPort {
  Future<void> kill(int pid);

  bool isPidAlive(int pid);
}
