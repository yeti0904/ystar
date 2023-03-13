import std.file;
import std.math;
import std.path;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import bindbc.sdl;
import video;
import types;

enum Texture {
	Bricks
}

class GameTextures {
	SDL_Texture*[Texture] textures;

	this() {
		auto support = loadSDLImage();
		// TODO: check if it failed
	
		if (!IMG_Init(IMG_INIT_PNG)) {
			stderr.writeln("Failed to initialise SDL_image");
			exit(1);
		}
	}

	~this() {
		IMG_Quit();
	}

	static GameTextures Instance() {
		static GameTextures inst;

		if (!inst) {
			inst = new GameTextures();
		}

		return inst;
	}

	void LoadTexture(Texture which, string rpath) { // rpath = relative path
		auto texture = IMG_LoadTexture(
			VideoComponents.Instance().renderer,
			toStringz(dirName(thisExePath()) ~ "/assets/" ~ rpath)
		);

		if (texture == null) {
			stderr.writeln("Failed to load texture");
		}

		textures[which] = texture;
	}

	void DrawAngledTexture(Texture which, Vec2!int pos, double angle, int scale) {
		auto     tex = textures[which];
		Vec2!int texSize;

		if (isNaN(angle)) {
			stderr.writeln("Error: angle is NaN");
			exit(1);
		}

		if (tex == null) {
			stderr.writeln("Tried to render NULL texture");
			exit(1);
		}

		SDL_QueryTexture(tex, null, null, &texSize.x, &texSize.y);
		SDL_Rect rect = SDL_Rect(
			pos.x, pos.y, texSize.x * scale, texSize.y * scale
		);

		SDL_RenderCopyEx(
			VideoComponents.Instance().renderer, tex, null, &rect, angle, null,
			SDL_FLIP_NONE
		);
	}
}
