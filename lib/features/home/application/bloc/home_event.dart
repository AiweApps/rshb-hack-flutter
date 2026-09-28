part of 'home_bloc.dart';

sealed class HomeEvent {
  const HomeEvent();
}

final class StartHome extends HomeEvent {
  const StartHome();
}

final class InitialSearch extends HomeEvent {
  final String query;

  InitialSearch({required this.query});
}

final class Search extends HomeEvent {
  final String query;

  Search({required this.query});
}

final class UpdateSearchQuery extends HomeEvent {
  final String query;

  UpdateSearchQuery({required this.query});
}
