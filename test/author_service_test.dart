import 'package:flutter_test/flutter_test.dart';
import 'package:bookery/services/author_service.dart';

void main() {
  test('AuthorService fetches and parses author info correctly', () async {
    final service = AuthorService();
    final author = await service.fetchAuthorInfo('J.R.R. Tolkien');
    
    expect(author, isNotNull);
    expect(author!.name, equals('J.R.R. Tolkien'));
    expect(author.bio, isNotEmpty);
    expect(author.birthDate, contains('1892'));
    expect(author.deathDate, contains('1973'));
  });
}
