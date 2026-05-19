import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/review_dao.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/network/github_content_client.dart';
import 'package:control_center/core/network/github_pr_client.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<CacheDao>(),
  MockSpec<ReviewDao>(),
  MockSpec<GitHubApiClient>(),
  MockSpec<GitHubPrClient>(),
  MockSpec<GitHubContentClient>(),
])
void main() {}
