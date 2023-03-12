import std.stdio;
import bindbc.sdl;
import raycaster;
import video;

class App {
	bool      running = true;
	Raycaster raycaster;

	this() {
		raycaster = new Raycaster();
		VideoComponents.Instance().Init("ystar example");
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
					raycaster.player.direction += cast(float) e.motion.xrel;
					break;
				}
				case SDL_KEYDOWN: {
					switch (e.key.keysym.scancode) {
						case SDL_SCANCODE_SPACE: {
							raycaster.player.upVelocity = 0.1;
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

