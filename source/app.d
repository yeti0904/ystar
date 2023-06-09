import std.stdio;
import bindbc.sdl;
import video;
import raycaster;
import textures;

class App {
	bool      running = true;
	Raycaster raycaster;

	this() {
		raycaster = new Raycaster();
		VideoComponents.Instance().Init("ystar example");

		auto textures = GameTextures.Instance();

		textures.LoadTexture(Texture.Bricks, "bricks.png");
	}

	void Update() {
		SDL_Event e;

		while (SDL_PollEvent(&e)) {
			switch (e.type) {
				case SDL_QUIT: {
					running = false;
					break;
				}
				case SDL_MOUSEMOTION: {
					auto video = VideoComponents.Instance();
				
					raycaster.player.direction   += cast(float) e.motion.xrel;
					raycaster.player.upDirection += cast(float) -(e.motion.yrel * 4);

					if (raycaster.player.upDirection > video.windowSize.y) {
						raycaster.player.upDirection = video.windowSize.y;
					}
					if (raycaster.player.upDirection < -video.windowSize.y) {
						raycaster.player.upDirection = -video.windowSize.y;
					}
					break;
				}
				case SDL_KEYDOWN: {
					switch (e.key.keysym.scancode) {
						case SDL_SCANCODE_SPACE: {
							if (raycaster.player.up == 0.0) {
								raycaster.player.upVelocity = 0.1;
							}
							break;
						}
						default: break;
					}
					break;
				}
				default: break;
			}
		}

		const ubyte* keystate = SDL_GetKeyboardState(null);

		raycaster.player.DoPhysics();

		raycaster.HandleInput(keystate);

		raycaster.Render3D();

		SDL_RenderPresent(VideoComponents.Instance().renderer);
	}
}

void main() {
	auto app = new App();

	while (app.running) {
		app.Update();
	}
}

