import '../database.dart';

/// DAO 基类：所有数据访问持有同一个 database，禁止在其它层拼 SQL（§2.3）。
abstract class BaseDao {
  BaseDao(this.db);

  final AppDatabase db;
}
