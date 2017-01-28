%%
% e = [0.005343 0.500454 0.003089];
e = [-0.19131 0.067411 -0.013171];
e0 = sqrt(1-sum(e.^2));
R = eye(3);
e1 = e(1);
e2 = e(2);
e3 = e(3);
R(1,:) = 2*[e0^2+e1^2-0.5 e1*e2+e0*e3 e1*e3-e0*e2];
R(2,:) = 2*[e1*e2-e0*e3 e0^2+e2^2-0.5 e2*e3+e0*e1];
R(3,1) = 2*(e1*e3+e0*e2);
R(3,2) = 2*(e2*e3-e0*e1);
R(3,3) = 2*(e0*e0+e3*e3-0.5);
R