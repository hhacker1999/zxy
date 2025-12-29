abstract class ViewItemState<T> {}

class ItemInitial<T> implements ViewItemState<T> {}

class ItemLoading<T> implements ViewItemState<T> {}

class ItemLoaded<T> implements ViewItemState<T> {
  final T value;

  const ItemLoaded({required this.value});
}

class ItemError<T> implements ViewItemState<T> {
  final String error;

  const ItemError({required this.error});
}
