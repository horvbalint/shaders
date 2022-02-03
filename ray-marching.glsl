const float MAX_DISTANCE = 10.0;
const float DISTANCE_TRESHOLD = 0.001;

const vec3 CAMERA_POS = vec3(0, 1, 0);
const float PLANE_HEIGHT = 0.0;
const float BALL_DIST = 4.0;
const vec3 BALL_POS = vec3(0, 1, BALL_DIST);
const float BALL_RADIUS = 0.5;

float getClosestDistanceFromObjects(vec3 position) {
    float distFromPlane = position.y - PLANE_HEIGHT;
    float distFromBall = length(position - BALL_POS) - BALL_RADIUS;
    
    return min(distFromPlane, distFromBall);
}

float rayMarch(vec3 from, vec3 direction) {
    float distanceTravaled = 0.0;
    float closestObjectDist = MAX_DISTANCE;
     
    while(distanceTravaled < MAX_DISTANCE && closestObjectDist > DISTANCE_TRESHOLD) {
        vec3 rayPosition = from + (direction * distanceTravaled);
        closestObjectDist = getClosestDistanceFromObjects(rayPosition);
        
        distanceTravaled += closestObjectDist;
    }
    
    return distanceTravaled;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy)/iResolution.y;
    
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));
    float distanceInRayDirection = rayMarch(CAMERA_POS, rayDirection);
    
    vec3 col = vec3(distanceInRayDirection/BALL_DIST/2.);

    fragColor = vec4(col, 1.0);
}