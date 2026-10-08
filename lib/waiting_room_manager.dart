class WaitingRoomManager {
  final List<String> _clients = [];
  List<String> get clients => List.unmodifiable(_clients);

  void addClient(String name) {
    _clients.add(name);
  }

  void removeClient(String name) {
    _clients.remove(name);
  }
}
