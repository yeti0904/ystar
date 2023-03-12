import std.math;
import std.algorithm;
import bindbc.sdl;
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
		RayHit ret;
		Vec2!float dir      = Vec2!float(
			CosDeg(player.direction + angleOffset), SinDeg(player.direction + angleOffset)
		);
		Vec2!float gradient = Vec2!float(dir.x / dir.y, dir.y / dir.x);
		Vec2!float unitStepSize;
		Vec2!float stepSize;

		ret.direction = player.direction + angleOffset;

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

			bool horizontal = false;

			if (len.x < len.y) {
				pos.x      += stepSize.x;
				distance    = len.x;
				len.x      += unitStepSize.x;
				horizontal  = true;
			}
			else {
				pos.y    += stepSize.y;
				distance  = len.y;
				len.y    += unitStepSize.y;
			}
		}

		Vec2!float hitPosition;

		hitPosition.x = player.pos.x + dir.x * distance;
		hitPosition.y = player.pos.y + dir.y * distance;

		ret.tile        = level.tiles[cast(int) pos.y][cast(int) pos.x];
		ret.distance    = distance;
		ret.hitPosition = hitPosition;

		return ret;
	}

	void HandleInput(const ubyte* keystate) {
		const float distance = 0.025;
	
		if (keystate[SDL_SCANCODE_W]) {
			player.pos = player.pos.MoveInDirection(player.direction, distance);
		}
		
		if (keystate[SDL_SCANCODE_S]) {
			player.pos = player.pos.MoveInDirection(player.direction + 180, distance);
		}

		if (keystate[SDL_SCANCODE_A]) {
			player.pos = player.pos.MoveInDirection(player.direction - 90, distance);
		}

		if (keystate[SDL_SCANCODE_D]) {
			player.pos = player.pos.MoveInDirection(player.direction + 90, distance);
		}

		if (keystate[SDL_SCANCODE_LEFT]) {
			player.direction -= 5.0;
		}

		if (keystate[SDL_SCANCODE_RIGHT]) {
			player.direction += 5.0;
		}
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
		auto video = VideoComponents.Instance();

		SDL_SetRenderDrawColor(video.renderer, 0, 0, 0, 255);
		SDL_RenderClear(video.renderer);

		int wallPos = 0;
		for (float i = 0 - (Raycaster.fov / 2); i < Raycaster.fov / 2; i += 0.1) {
			auto ray = Raycast(i);

			ray.distance *= CosDeg(player.direction - ray.direction);

			int halfWin = video.windowSize.y / 2;

			int wallHeight = cast(int) round(1.0 / ray.distance * video.windowSize.y);

			int yOffset = cast(int) (player.up * wallHeight);

			if (wallHeight < 0) {
				wallHeight = 0;
			}

			ubyte brightness = cast(ubyte) max(
				255 - cast(int) (ray.distance * 10), 0
			);

			SDL_SetRenderDrawColor(
				video.renderer, brightness, brightness, brightness, 255
			);

			SDL_RenderDrawLine(
				video.renderer, wallPos, (halfWin - wallHeight / 2) + yOffset,
				wallPos, (halfWin + wallHeight / 2) + yOffset
			);

			++ wallPos;
		}
	}
}
