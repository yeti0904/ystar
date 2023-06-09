import std.math;
import math;

struct Vec2(T) {
	T x, y;

	this(T px, T py) {
		x = px;
		y = py;
	}

	double AngleTo(Vec2!T to) {
		return atan2(cast(float) (to.y - y), cast(float) (to.x - x));
	}

	Vec2!int ToIntVec() {
		return Vec2!int(cast(int) x, cast(int) y);
	}

	Vec2!float ToFloatVec() {
		return Vec2!float(cast(float) x, cast(float) y);
	}

	Vec2!float MoveInDirection(float direction, float multiplier) {
		return Vec2!float(
			x + CosDeg(direction) * multiplier,
			y + SinDeg(direction) * multiplier
		);
	}

	float DistanceTo(Vec2!T other) {
		float width  = abs(other.x - x);
		float height = abs(other.y - y);

		return sqrt(width * width + height * height);
	}
}
