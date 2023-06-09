import std.file;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import bindbc.sdl;
import types;

import loader = bindbc.loader.sharedlib;

class VideoComponents {
	SDL_Window*   window;
	SDL_Renderer* renderer;
	Vec2!int      windowSize;

	this() {
		
	}

	~this() {
		SDL_DestroyWindow(window);
		SDL_DestroyRenderer(renderer);
		SDL_Quit();
	}

	static VideoComponents Instance() {
		static VideoComponents ret;

		if (!ret) {
			ret = new VideoComponents();
		}

		return ret;
	}

	void Init(string windowName) {
		// load SDL
		SDLSupport support = loadSDL();
		if (support != sdlSupport) {
			stderr.writeln("Failed to load SDL");

			foreach (i, ref error ; loader.errors) {
				stderr.writefln("Error %d", i + 1);
				stderr.writefln("Error: %s", fromStringz(error.error));
				stderr.writefln("Info: %s", fromStringz(error.message));
			}

			SDL_version sdlVersion;
			SDL_GetVersion(&sdlVersion);

			stderr.writefln(
				"SDL Version: %d.%d.%d",
				sdlVersion.major, sdlVersion.minor, sdlVersion.patch
			);
			
			exit(1);
		}
		version (Windows) {
			loadSDL(dirName(thisExePath()) ~ "/sdl2.dll");
		}

		// init
		if (SDL_Init(SDL_INIT_VIDEO) < 0) {
			stderr.writefln("Failed to init SDL: %s", fromStringz(SDL_GetError()));
			exit(1);
		}

		// window
		windowSize = Vec2!int(900, 450);
		window = SDL_CreateWindow(
			cast(char*) toStringz(windowName),
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
			windowSize.x * 2, windowSize.y * 2, SDL_WINDOW_RESIZABLE
		);
		if (window is null) {
			stderr.writefln("Failed to create window: %s", fromStringz(SDL_GetError()));
			exit(1);
		}

		SDL_SetRelativeMouseMode(SDL_TRUE);
		
		renderer = SDL_CreateRenderer(
			window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
		);
		if (renderer is null) {
			stderr.writefln("Failed to create renderer: %s", fromStringz(SDL_GetError()));
			exit(1);
		}

		// SDL_RenderSetScale(renderer, 8.0, 8.0);
		SDL_RenderSetLogicalSize(renderer, windowSize.x, windowSize.y);
	}

	void SetHexColour(uint colour) {
		SDL_SetRenderDrawColor(
			renderer,
			cast(ubyte) ((colour & 0xFF0000) >> 16), // R
			cast(ubyte) ((colour & 0x00FF00) >> 8),  // G
			cast(ubyte) (colour & 0x0000FF),         // B
			255
		);
	}

	SDL_Color ColourFromHex(uint colour) {
		return SDL_Color(
			cast(ubyte) ((colour & 0xFF0000) >> 16), // R,
			cast(ubyte) ((colour & 0x00FF00) >> 8), // G,
			cast(ubyte) (colour & 0x0000FF),        // B,
			255
		);
	}
}
