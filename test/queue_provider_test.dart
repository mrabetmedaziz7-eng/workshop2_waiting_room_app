import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  test('should add a client to the waiting list', () {
    final provider = QueueProvider();
    provider.addClient('John Doe');
    expect(provider.clients.length, 1);
    expect(provider.clients.first, 'John Doe');
  });

  test('should remove a client from the waiting list', () {
    final provider = QueueProvider();
    provider.addClient('John Doe');
    provider.addClient('Jane Doe');
    provider.removeClient('John Doe');
    expect(provider.clients.length, 1);
    expect(provider.clients.first, 'Jane Doe');
  });

  test('should remove the first client when nextClient() is called', () {
    final provider = QueueProvider();
    provider.addClient('Client A');
    provider.addClient('Client B');
    provider.nextClient();
    expect(provider.clients.length, 1);
    expect(provider.clients.first, 'Client B');
  });

  test('nextClient() on an empty list does not throw and leaves the list empty', () {
    final provider = QueueProvider();
    expect(() => provider.nextClient(), returnsNormally);
    expect(provider.clients, isEmpty);
  });

  test('listeners are notified when addClient, removeClient, and nextClient are called', () {
    final provider = QueueProvider();
    int notificationCount = 0;
    provider.addListener(() {
      notificationCount++;
    });

    provider.addClient('Client 1');
    expect(notificationCount, 1);

    provider.nextClient();
    expect(notificationCount, 2);

    provider.addClient('Client 2');
    expect(notificationCount, 3);

    provider.removeClient('Client 2');
    expect(notificationCount, 4);
  });
}
