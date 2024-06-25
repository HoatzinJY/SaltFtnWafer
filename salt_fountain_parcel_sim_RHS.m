function f=salt_fountain_parcel_sim_RHS(t,y)

% SALT_FOUNTAIN_PARCEL_SIM_RHS(T,Y) is used to solve three coupled
% equations for the vertical acceleration, temperature, and vertical  
% position of a plug of water in a salt fountain
%
% t is the time
% y(1)=Z ,i.e. the vertical position of the plug
% y(2)=w ,i.e. the vertical velocity of the plug
% y(3)=T_p, i.e. the temperature of the plug
% f(1)=DZ/Dt=w
% f(2)=Dw/Dt=b+D, buoyancy + drag
% f(3)=DT_p/Dt=2*k_th*(T_b-T_p)/(dx*r*rho_o*c_p), change do to heat flux
% through side of pipe

global k_th dx r beta_s alpha_t T_b S_b S_p z_b do_pump

T_i=interp1(z_b,T_b,y(1));
S_i=interp1(z_b,S_b,y(1));

nu=1e-6; %molecular kinematic viscosity of water [m^2/s]

% first ode for dz/dt - vertical velocity
f(1)=y(2);

%second ode for dw/dt - vertical acceleration 
if do_pump
    f(2)=0;
else
f(2)=-9.8*(beta_s*(S_p-S_i)-alpha_t*(y(3)-T_i))-8*nu*y(2)/(r^2);
end

%third ode for dT/dt - change in temperature 
f(3)=2*k_th*(T_i-y(3))/(dx*r*1000*4.18e3);

Ib=find(isnan(f));
if ~isempty(Ib)
    f(Ib)=0;
end
f=f(:);
    