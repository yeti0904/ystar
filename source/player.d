import types;

class Player {
	Vec2!float pos;
	float      up;
	float      direction;
	float      upDirection;
	float      upVelocity;

	this() {
		pos         = Vec2!float(0.0, 0.0);
		direction   = 0.0;
		up          = 0.0;
		upVelocity  = 0.0;
		upDirection = 0.0;
	}

	void DoPhysics() {
		upVelocity -= 0.005;
		up         += upVelocity;

		if (up < 0.0) {
			up         = 0.0;
			upVelocity = 0.0;
		}
	}
}
