pragma circom 2.0.0;

// Location claim for the OpenCharities proof app.
// Proves: "The photo was taken within R of the project site"
// without revealing the exact location.
//
// Coordinates are integers: microdegrees plus an offset, so they are never negative
//   latInt = round(latitude  * 1,000,000) + 90,000,000
//   lonInt = round(longitude * 1,000,000) + 180,000,000

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";
include "node_modules/circomlib/circuits/bitify.circom";

template LocationClaim() {
    // ---- private inputs: only the NGO knows these ----
    signal input lat;      // exact latitude of the photo
    signal input lon;      // exact longitude of the photo
    signal input salt;     // random secret, so nobody can guess the location from the commitment

    // ---- public inputs: everyone sees these ----
    signal input commitment;  // Poseidon(lat, lon, salt), stored on the blockchain at capture time
    signal input centerLat;   // project site
    signal input centerLon;
    signal input cosK;        // cos(latitude of site) * 1000, corrects longitude distances
    signal input radius;      // radius in microdegrees of latitude

    // 1) The secret values belong to the commitment on the blockchain.
    component h = Poseidon(3);
    h.inputs[0] <== lat;
    h.inputs[1] <== lon;
    h.inputs[2] <== salt;
    h.out === commitment;

    // 2) Coordinates are in a valid range (32 bit is enough).
    component rLat = Num2Bits(32); rLat.in <== lat;
    component rLon = Num2Bits(32); rLon.in <== lon;

    // 3) Distance check: (dLat*1000)^2 + (dLon*cosK)^2 <= (radius*1000)^2
    signal dLat; dLat <== (lat - centerLat) * 1000;
    signal dLon; dLon <== (lon - centerLon) * cosK;
    signal a; a <== dLat * dLat;
    signal b; b <== dLon * dLon;
    signal r; r <== radius * 1000;
    signal r2; r2 <== r * r;

    component inside = LessEqThan(128);
    inside.in[0] <== a + b;
    inside.in[1] <== r2;
    inside.out === 1;
}

component main {public [commitment, centerLat, centerLon, cosK, radius]} = LocationClaim();
