/// Persistence boundary for the all-time best score.
abstract interface class ScoreStore {
  int load();
  void save(int score);
}

/// Volatile store used by tests and as the default until a real
/// implementation is wired in.
final class MemoryScoreStore implements ScoreStore {
  MemoryScoreStore([this._score = 0]);

  int _score;

  @override
  int load() => _score;

  @override
  void save(int score) => _score = score;
}
