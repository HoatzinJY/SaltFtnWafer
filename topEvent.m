function [value, isterminal, direction] = topEvent(t, y)
%this function creates an event once the parcel has hit the top of the pipe

% t is the time
% y(1)=Z ,i.e. the vertical position of the plug
% y(2)=w ,i.e. the vertical velocity of the plug
% y(3)=T_p, i.e. the temperature of the plug
% f(1)=DZ/Dt=w
% f(2)=Dw/Dt=b+D, buoyancy + drag
% f(3)=DT_p/Dt=2*k_th*(T_b-T_p)/(dx*r*rho_o*c_p), change do to heat flux
% through side of pipe

global z_top;

if (y(1) > z_top)
    value = 0;
else 
    value = 1;
end

isterminal = 1;
direction = 0;

end

