%salt_fountain_parcel_sim.m
% tracks the evolution of the physical conditions of one plug of water
% as it travels up the pipe 

%fasttrack paramters
my_pipe_length = 200; %m
my_pipe_radius = 0.5; %m
my_time_post_pump = 5; %days
my_distance_raised = 10; %m

%start of normal file

seawater_dir= ['\Users\jaime\Documents\ArtificialUpwelling\Wafer_Model\seawater'];
path (path, seawater_dir);


% get salinity and temperature profiles from World Ocean Atlas

month=6;

if month<10
    fnameT='\Users\jaime\Documents\ArtificialUpwelling\WOA18\woa18_decav_t0month_01.nc';
    fnameS='\Users\jaime\Documents\ArtificialUpwelling\WOA18\woa18_decav_s0month_01.nc';
else
    fnameT='\Users\jaime\Documents\ArtificialUpwelling\WOA18\woa18_decav_tmonth_01.nc';
    fnameS='\Users\jaime\Documents\ArtificialUpwelling\WOA18\woa18_decav_s0month_01.nc';
   
end
fnameT=strrep(fnameT,'month',int2str(month));
fnameS=strrep(fnameS,'month',int2str(month));


ncid = netcdf.open(fnameT, 'NC_NOWRITE');

lon_ID = netcdf.inqVarID(ncid,'lon');
lon = netcdf.getVar(ncid,lon_ID,'double');

lat_ID = netcdf.inqVarID(ncid,'lat');
lat = netcdf.getVar(ncid,lat_ID,'double');

depth_ID = netcdf.inqVarID(ncid,'depth');
depth = netcdf.getVar(ncid,depth_ID,'double');

netcdf.close(ncid);

%specify the lat and lon near profile of interest
lat_p=22;
lon_p=-150;

Ig=find(lon>=lon_p);
Jg=find(lat>=lat_p);

Ip=Ig(1);
Jp=Jg(1);

T = double(squeeze(ncread(fnameT,'t_an',[Ip Jp 1 1],[1 1 Inf Inf])));
S = double(squeeze(ncread(fnameS,'s_an',[Ip Jp 1 1],[1 1 Inf Inf])));

% top and bottom of the salt fountain
% PARAM: salt fountain height
z_top=-100;
z_bot= z_top - my_pipe_length;
% z_bot=-300;

% this following section plots the temperature and salinity profiles of
% location
figure
subplot(1,2,1)
plot(T,-depth)
aa=axis;
hold on
plot([aa(1) aa(2)],z_bot*[1 1],'k--');
aa=axis;
hold on
plot([aa(1) aa(2)],z_top*[1 1],'k--');
axis(aa);
grid on
xlabel('T (C)');
ylabel('z (m)');
set(gca,'fontsize',14);
subplot(1,2,2)
plot(S,-depth)
aa=axis;
hold on
plot([aa(1) aa(2)],z_bot*[1 1],'k--');
aa=axis;
hold on
plot([aa(1) aa(2)],z_top*[1 1],'k--');
axis(aa);
grid on
set(gca,'fontsize',14);
xlabel('S (psu)');

%interpolate the temperature and salinity profiles to a higher resolution
%vertical grid, starting at a depth H
%PARAM: domain grid 
dz=1; %in meters
H=500;
if H<-z_bot
    display('the depth of the grid must be deeper than the depth of the pipe!')
   return 
end
z_grd=-H:dz:0;
z_grd=z_grd(:);
T_grd=interp1(-depth,T,z_grd);
S_grd=interp1(-depth,S,z_grd);

%all final time values in seconds
%PARAM: amount of perturbation
w_pump=20; %in meters per day
t_pump = (my_distance_raised/w_pump) * 86400;%sets pump duration based on desired perturbation @ fixed Vw
w_pump=w_pump/86400; %convert to meters per second
%t_pump=4*86400; %duration pump is on
%PARAM: time that salt fountain runs for after perturbation
t_sf=my_time_post_pump*86400; %duration salt fountain is integrated after pump is turned off

% run in two stages: pump on and pump off
for ii=1:2 % ii=1, pump is on, ii=2, pump is off

    ii
    
    %specify the properties of the salt fountain that will be passed into the
    %ODE solver
    
    global k_th dx r beta_s alpha_t T_b S_b S_p z_b do_pump
    
    %PARAM: various pipe parameters
    k_th=0.15; %thermal conductivity in W/m/K in this case for PVC
    %k_th=1; %thermal conductivity in W/m/K 
    dx=0.01; %thickness of the pipe
    r=my_pipe_radius; %radius of the pipe
    T_b=T_grd; %background temperature profile
    S_b=S_grd; %background salinity profile
    z_b=z_grd; %vertical coordinate of background T, S profile
    
    %calculate the value of the haline contraction coefficient and
    %thermal expansion coefficient averaged over the length of the fountain
    
    Kg=find(z_grd>=z_bot & z_grd<z_top);
    pres=sw_pres(-z_grd,lat_p);
    
    alpha_t=mean(sw_alpha(S_grd(Kg),T_grd(Kg),pres(Kg),'temp'));
    beta_s=mean(sw_beta(S_grd(Kg),T_grd(Kg),pres(Kg),'temp'));
    
    if ii==1 %pump on
    do_pump=1; %if do_pump=1, the RHS of the vertical velocity equation will be 
               % set to zero, and thus the vertical velocity will remain equal 
               % to its initial value which is given by the pump's vertical
               % velocity
    else %pump off 
        do_pump=0;
    end
               
    S_p=S_b(Kg(1)); %the salinity of the plug of water which is conserved
    
    % set initial conditions during pumping phase to be as measured in water column
    % at base of pipe
    if ii==1
    tspan=[0 t_pump];
    Z_o=z_b(Kg(1)); %initial vertial position of plug
    W_o=w_pump; %initial vertical velocity of plug
    T_o=T_b(Kg(1));  %inital temperature of plug
    
    % plug var column 1 is depth, 2 is velocity, 3 is temperature 
    % sets initial conditions after pumping phase to be whatever it was after 
    % the last time step
    else
        tspan=[0 t_sf];
        Z_o=plug_var(end,1); 
        W_o=plug_var(end,2);
        T_o=plug_var(end,3);
    end
    
    % puts initial conditions into matrix
    % read off 
    ics=[Z_o W_o T_o];
    ics=ics(:);
    
    %this is the ode solver (4th-5th order), ode45 
    %PARAM: time step --> automatically determined by solver 
    [t,plug_var]=ode45('salt_fountain_parcel_sim_RHS',tspan,ics);
    
    %sets imaginary surface boundary
    Ib=find(plug_var(:,1)>0); 

    plug_var(Ib,:)=NaN;
    
    clear global
    
    %stores pump phase and non pump phases data together
    if ii==1
        t_w_pump=t;
        plug_var_w_pump=plug_var;
    else
        t_total=cat(1,t_w_pump,t+t_w_pump(end));
        plug_var_total=cat(1,plug_var_w_pump,plug_var);
    end

end

%second set of plots of pipe conditions vs time (in days)
%plug_var_total has column 1 is depth, 2 is velocity, 3 is temperature 
figure
subplot(2,1,1)
plot(t_total/86400,plug_var_total(:,1))
xlabel('Time (in days)')
ylabel('Depth of Parcel(m)')
grid on
subplot(2,1,2)
plot(t_total/86400,plug_var_total(:,3))
xlabel('Time (in days)')
ylabel('Temperature (C)')
grid on

