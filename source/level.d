import types;

enum TileType {
	Empty,
	Wall
}

struct Tile {
	TileType type;
}

class Level {
	Tile[][] tiles;

	this(size_t w, size_t h) {
		tiles = new Tile[][](w, h);
	}

	static Level FromCharacters(string[] level) {
		Level ret;
	
		foreach (ref line ; level) {
			assert(line.length == level[0].length);
		}

		ret = new Level(level.length, level[0].length);

		foreach (i, ref line ; level) {
			foreach (j, ref ch ; line) {
				Tile set;
			
				switch (ch) {
					case '#': {
						set.type = TileType.Wall;
						break;
					}
					case ' ': {
						set.type = TileType.Empty;
						break;
					}
					default: assert(0);
				}

				ret.SetTile(Vec2!size_t(j, i), set);
			}
		}

		return ret;
	}

	void SetTile(Vec2!size_t pos, Tile tile) {
		tiles[pos.y][pos.x] = tile;
	}
}
