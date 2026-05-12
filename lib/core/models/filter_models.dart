import 'package:equatable/equatable.dart';

class ExploreFilters extends Equatable {
  final String query;
  final bool availableOnly;
  final double? maxRate;
  final double minRating;

  const ExploreFilters({
    this.query = '',
    this.availableOnly = false,
    this.maxRate,
    this.minRating = 0,
  });

  @override
  List<Object?> get props => [query, availableOnly, maxRate, minRating];
}

class GigFilters extends Equatable {
  final String? category;
  final String? status;

  const GigFilters({
    this.category,
    this.status,
  });

  @override
  List<Object?> get props => [category, status];
}
