import std.math;
import std.algorithm;
import bindbc.sdl;
import textures;
import level;
import player;
import types;
import video;
import math;

struct RayHit {
	Tile       tile;
	float      distance;
	float      direction;
	Vec2!float hitPosition;
	bool       horizontal;
}

class Raycaster {
	Level  level;
	Player player;
	
	static float fov = 90;

	this() {
		level = Level.FromCharacters([
			"#########################",
			"#           #           #",
			"#           #           #",
			"#     #     #           #",
			"#    ###                #",
			"#     #     #           #",
			"#           #           #",
			"#           #           #",
			"###### ########### ######",
			"#           #           #",
			"#           #           #",
			"#           #           #",
			"#                       #",
			"#           #           #",
			"#           #           #",
			"#           #           #",
			"#########################",
		]);

		player     = new Player();
		player.pos = Vec2!float(1.5, 1.5);
	}

	RayHit Raycast(float angleOffset) {
		auto video = VideoComponents.Instance();
	
		RayHit ret;
		float direction = player.direction +
			Atan2Deg(
				angleOffset - video.windowSize.x / 2,
				(video.windowSize.x / 2 / TanDeg(Raycaster.fov / 2))
			);
		Vec2!float dir      = Vec2!float(
			CosDeg(direction), SinDeg(direction)
		);
		Vec2!float gradient = Vec2!float(dir.x / dir.y, dir.y / dir.x);
		Vec2!float unitStepSize;
		Vec2!float stepSize;

		ret.direction = direction;

		unitStepSize.x = sqrt(1 + (gradient.y * gradient.y));
		unitStepSize.y = sqrt((gradient.x * gradient.x) + 1);

		Vec2!float len;
		Vec2!float pos = Vec2!float(floor(player.pos.x), floor(player.pos.y));

		if (dir.x < 0) {
			stepSize.x = -1;
		
			len.x = (player.pos.x - pos.x) * unitStepSize.x;
		}
		else {
			stepSize.x = 1;

			len.x = (pos.x + 1 - player.pos.x ) * unitStepSize.x;
		}

		if (dir.y < 0) {
			stepSize.y = -1;
		
			len.y = (player.pos.y - pos.y) * unitStepSize.y;
		}
		else {
			stepSize.y = 1;

			len.y = (pos.y + 1 - player.pos.y) * unitStepSize.y;
		}

		float distance;
		bool  horizontal;

		while (true) {
			Vec2!int posInt = Vec2!int(cast(int) pos.x, cast(int) pos.y);

			if (
				(posInt.x >= level.tiles[0].length) ||
				(posInt.y >= level.tiles.length)
			) {
				break;
			}
			if (level.tiles[posInt.y][posInt.x].type != TileType.Empty) {
				break;
			}

			if (len.x < len.y) {
				pos.x      += stepSize.x;
				distance    = len.x;
				len.x      += unitStepSize.x;
				horizontal  = true;
			}
			else {
				pos.y      += stepSize.y;
				distance    = len.y;
				len.y      += unitStepSize.y;
				horizontal  = false;
			}
		}

		Vec2!float hitPosition;

		hitPosition.x = player.pos.x + dir.x * distance;
		hitPosition.y = player.pos.y + dir.y * distance;

		ret.tile        = level.tiles[cast(int) pos.y][cast(int) pos.x];
		ret.distance    = distance;
		ret.hitPosition = hitPosition;
		ret.horizontal  = horizontal;

		return ret;
	}

	void HandleInput(const ubyte* keystate) {
		const float distance = 0.025;

		auto oldPos = player.pos;

		void MovePlayer(Vec2!float newPos) {
			player.pos.x = newPos.x;

			if (PlayerInsideBlock()) {
				player.pos.x = oldPos.x;
			}

			player.pos.y = newPos.y;

			if (PlayerInsideBlock()) {
				player.pos.y = oldPos.y;
			}
		}
	
		if (keystate[SDL_SCANCODE_W]) {
			MovePlayer(player.pos.MoveInDirection(player.direction, distance));
		}
		
		if (keystate[SDL_SCANCODE_S]) {
			MovePlayer(player.pos.MoveInDirection(player.direction + 180, distance));
		}

		if (keystate[SDL_SCANCODE_A]) {
			MovePlayer(player.pos.MoveInDirection(player.direction - 90, distance));
		}

		if (keystate[SDL_SCANCODE_D]) {
			MovePlayer(player.pos.MoveInDirection(player.direction + 90, distance));
		}

		if (keystate[SDL_SCANCODE_LEFT]) {
			player.direction -= 5.0;
		}

		if (keystate[SDL_SCANCODE_RIGHT]) {
			player.direction += 5.0;
		}
	}

	bool PlayerInsideBlock() {
		Vec2!int playerTile = Vec2!int(
			cast(int) floor(player.pos.x),
			cast(int) floor(player.pos.y)
		);

		return level.tiles[playerTile.y][playerTile.x].type != TileType.Empty;
	}

	void Render2D() {
		auto        video     = VideoComponents.Instance();
		const int   tileSize  = 128;
		const float tileSizeF = cast(float) tileSize;

		SDL_SetRenderDrawColor(video.renderer, 0, 0, 0, 255);
		SDL_RenderClear(video.renderer);

		foreach (i, ref line ; level.tiles) {
			foreach (j, ref tile ; line) {
				SDL_Rect tileRect = SDL_Rect(
					cast(int) j * tileSize, cast(int) i * tileSize,
					tileSize + 1, tileSize + 1
				);

				SDL_SetRenderDrawColor(video.renderer, 0, 0, 255, 255);

				if (tile.type == TileType.Wall) {
					SDL_RenderFillRect(video.renderer, &tileRect);
				}
				else {
					SDL_RenderDrawRect(video.renderer, &tileRect);
				}
			}
		}

		Vec2!int playerRenderPos = Vec2!int(
			cast(int) (player.pos.x * tileSizeF),
			cast(int) (player.pos.y * tileSizeF)
		);

		// draw rays
		SDL_SetRenderDrawColor(video.renderer, 0, 255, 0, 255);
		RayHit[] rays;

		for (float i = 0 - (Raycaster.fov / 2); i < Raycaster.fov / 2; i += 1.0) {
			rays ~= Raycast(i);
		}

		foreach (ref ray ; rays) {
			Vec2!int rayEnd = Vec2!int(
				cast(int) (ray.hitPosition.x * tileSizeF),
				cast(int) (ray.hitPosition.y * tileSizeF)
			);

			SDL_RenderDrawLine(
				video.renderer, playerRenderPos.x, playerRenderPos.y,
				rayEnd.x, rayEnd.y
			);
		}
		

		SDL_SetRenderDrawColor(video.renderer, 150, 150, 150, 255);

		{
			Vec2!float lineEnd = playerRenderPos.MoveInDirection(player.direction, 5.0);

			SDL_RenderDrawLine(
				video.renderer, playerRenderPos.x, playerRenderPos.y,
				cast(int) lineEnd.x, cast(int) lineEnd.y
			);
		}
		
		SDL_SetRenderDrawColor(video.renderer, 255, 255, 255, 255);
		SDL_RenderDrawPoint(video.renderer, playerRenderPos.x, playerRenderPos.y);
	}

	void Render3D() {
		auto video    = VideoComponents.Instance();
		auto textures = GameTextures.Instance();

		SDL_SetRenderDrawColor(video.renderer, 0, 0, 0, 255);
		SDL_RenderClear(video.renderer);

		int wallPos = 0;
		for (float i = 0; i < cast(float) video.windowSize.x; ++i) {
			auto ray = Raycast(i);

			ray.distance *= CosDeg(player.direction - ray.direction);

			int halfWin = video.windowSize.y / 2;

			int wallHeight = cast(int) round(1.0 / ray.distance * video.windowSize.y);

			int yOffset  = cast(int) (player.up * wallHeight);
			yOffset     += cast(int) player.upDirection;

			if (wallHeight < 0) {
				wallHeight = 0;
			}

			ubyte brightness = cast(ubyte) max(
				255 - cast(int) (ray.distance * 10), 0
			);

			SDL_SetRenderDrawColor(
				video.renderer, brightness, brightness, brightness, 255
			);

			/*SDL_RenderDrawLine(
				video.renderer, wallPos, (halfWin - wallHeight / 2) + yOffset,
				wallPos, (halfWin + wallHeight / 2) + yOffset
			);*/

			auto texture = textures.textures[Texture.Bricks];

			SDL_Rect dest;
			dest.x = wallPos;
			dest.y = (halfWin - wallHeight / 2) + yOffset;
			dest.w = 1;
			dest.h = wallHeight;

			Vec2!int textureSize;
			SDL_QueryTexture(texture, null, null, &textureSize.x, &textureSize.y);

			SDL_Rect src;
			src.y = 0;
			src.w = 1;
			src.h = textureSize.y;

			if (ray.horizontal) {
				src.x = cast(int)
					((ray.hitPosition.y - floor(ray.hitPosition.y)) * textureSize.x);
			}
			else {
				src.x = cast(int)
					((ray.hitPosition.x - floor(ray.hitPosition.x)) * textureSize.x);
			}

			SDL_RenderCopy(video.renderer, texture, &src, &dest);
			++ wallPos;
		}
	}
}
