import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base Use Case contract
/// [Type] = Return type, [Params] = Input parameters
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// For use cases with no parameters
class NoParams {}

/// For use cases that return a Stream
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}
