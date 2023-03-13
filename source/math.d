import std.math;

float CosDeg(float degrees) {
	return cos(degrees * (PI / 180));
}

float SinDeg(float degrees) {
	return sin(degrees * (PI / 180));
}

float TanDeg(float degrees) {
	return tan(degrees * (PI / 180));
}

float Atan2Deg(float a, float b) {
	return atan2(a, b) * (180 / PI);
}
