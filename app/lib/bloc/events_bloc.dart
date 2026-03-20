import 'dart:async';

abstract class BaseEvent {}
class UpdatedHomeList implements BaseEvent {}
class UpdatedLibrary implements BaseEvent {}


class EventsBloc {
  late final StreamController<BaseEvent> _controller;

  EventsBloc() {
    _controller = StreamController.broadcast();
  }

  Stream<BaseEvent> get eventStream => _controller.stream;

  void addEvent(BaseEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
