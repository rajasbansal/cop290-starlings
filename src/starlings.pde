class Boid {

  PVector position;
  PVector velocity;
  PVector acceleration;
  ArrayList<Boid> neighbors;
  int decision_timer = 0;

  Boid(float x, float y) {
    acceleration = new PVector(0, 0);
    float angle = random(TWO_PI);

    velocity = new PVector(cos(angle), sin(angle));
    position = new PVector(x, y);
  }

  void calc_neighbours(ArrayList<Boid> boids){
    ArrayList<Boid> next_neighbors = new ArrayList<Boid>();
    for (Boid other:boids){
      float d = PVector.dist(position, other.position);
      if (d>0 && d<maxr && this!=other){
        next_neighbors.add(other);
      }
    }
    neighbors = next_neighbors;
  }
  void run(ArrayList<Boid> boids) {
    if (decision_timer == 0){
      calc_neighbours(boids);
    }
    increment();
    flock(boids);
    update();
    borders();
    // render();
  }
  void increment(){
    decision_timer = (decision_timer + 1) % time_for_update;
  }
  void applyForce(PVector force) {
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids) {
    PVector sep = separate();   // Separation
    PVector ali = align();      // Alignment
    PVector coh = cohesion();   // Cohesion
    PVector noise = new PVector(random(2) - 1, random(2) -1); 
    PVector obst = avoidObstacles();
    // Arbitrarily weight these forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(2.0);
    noise.mult(0.05);
    obst.mult(2.0);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    applyForce(noise);
    applyForce(obst);
  }

  // Method to update position
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  }

  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);  // A vector pointing from the position to the target
    desired.normalize();
    desired.mult(maxspeed);
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  
    return steer;
  }

  void render() {
    float theta = velocity.heading2D() + radians(90);
    
    fill(200, 100);
    stroke(255);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
  }

  // Wraparound
  void borders() {
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
  }

  PVector separate () {
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    for (Boid other : neighbors) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < desiredseparation)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d);        
        steer.add(diff);
        count++;      
      }
    }

    if (count > 0) {
      steer.div((float)count);
    }

    if (steer.mag() > 0) {
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  PVector align () {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : neighbors) {
      sum.add(other.velocity);
      count++;
    }
    if (count > 0) {
      sum.div((float)count);
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

 
   PVector cohesion () {
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all positions
    int count = 0;
    for (Boid other : neighbors) {
        sum.add(other.position); 
        count++;
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the position
    } 
    else {
      return new PVector(0, 0);
    }
  }

  PVector avoidObstacles(){
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    for (Obstacle other : obstacles) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < obstacle_separation)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d);        
        steer.add(diff);
        count++;      
      }
    }
    return steer;
  }
}

