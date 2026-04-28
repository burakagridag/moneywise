// Sealed failure types for domain-layer error handling.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
