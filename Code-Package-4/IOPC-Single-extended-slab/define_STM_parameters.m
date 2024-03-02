function [STM_data] = define_STM_parameters(GPU_flag,init_data,source_data,...
    del_eps,spat_freq_fact,f_mod,grat_width)
%--------------------------------------------------------------------------
if GPU_flag==1
del_eps=gpuArray(del_eps);
spat_freq_fact=gpuArray(spat_freq_fact);
f_mod=gpuArray(f_mod);
grat_width=gpuArray(grat_width);
fsrc=gpuArray(init_data.fsrc);
Nz=gpuArray(init_data.Nz);
Ny=gpuArray(init_data.Ny);
dy=gpuArray(init_data.dy);
dz=gpuArray(init_data.dy);
kref=gpuArray(init_data.kref);
epsilon_ij=gpuArray(init_data.epsilon_ij);
src_y=gpuArray(source_data.src_y);
beam_width=gpuArray(source_data.beam_width);
mask=gpuArray(zeros(Ny,Nz));
else
fsrc=init_data.fsrc;
Nz=init_data.Nz;
Ny=init_data.Ny;
dy=init_data.dy;
dz=init_data.dy;
dt=init_data.dt;
src_z_start=source_data.src_z;
kref=init_data.kref;
epsilon_ij=init_data.epsilon_ij;
src_y=source_data.src_y;
beam_width=source_data.beam_width;
mask=zeros(Ny,Nz);
end

start_slab1=init_data.start_slab1;
start_slab2=init_data.start_slab2;
scat_width=init_data.scat_width;

dt=init_data.dt;
fsrc_SB=fsrc+f_mod; % upconverted wavefront frequency taken
%(grat_width-1)*kref*dz;

STM_start_z=floor((init_data.start_slab1+init_data.scat_width+...
    init_data.start_slab2)/2)-floor(grat_width/2);
STM_end_z=STM_start_z+grat_width-1;
STM_start_y=floor(0.5*Ny)-floor(0.1*Ny);
STM_end_y=floor(0.5*Ny)+floor(0.1*Ny);

[~,krefY]=meshgrid((0:Nz-1).*(kref*dz),(0:Ny-1).*(kref*dy));

omega_mod=2*pi*f_mod;
kmod=spat_freq_fact*kref;
mask(STM_start_y:STM_end_y,STM_start_z:STM_end_z)=1;

STM_center_krefy_loc=floor((Ny-1)*kref*dy/2);

STM_width_fact=floor(abs(STM_end_y-STM_start_y)*kref*dy/4);
gaussian_STM=exp(-((krefY-STM_center_krefy_loc).^2)./(STM_width_fact^2));

%-------------------------- grating ---------------------------------------
% Without spatial Gaussian modulation and full size
%eps_ij_n    = @(t_count) (epsilon_ij(2:end-1,2:end-1) + mask.*del_eps.*(1+sin(spat_freq_fact.*krefY-omega_mod*(t_count-1)*dt)));
% With spatial Gaussian modulation
eps_ij_n    = @(t_count) (epsilon_ij(2:end-1,2:end-1) + mask.*del_eps.*(1+sin(spat_freq_fact.*krefY-omega_mod*(t_count-1)*dt)).*gaussian_STM);
Dneps_ij_n  = @(t_count)   -omega_mod.*mask.*del_eps.*cos(spat_freq_fact.*krefY-omega_mod*(t_count-1)*dt);
D2neps_ij_n = @(t_count)   -(omega_mod^2).*mask.*del_eps.*sin(spat_freq_fact.*krefY-omega_mod*(t_count-1)*dt);
%----------------------------- STM_data -----------------------------------
STM_data.del_eps=del_eps;
STM_data.spat_freq_fact=spat_freq_fact;
STM_data.f_mod=f_mod;
STM_data.fsrc_SB=fsrc_SB;
STM_data.grat_width=grat_width;
STM_data.STM_start_z=STM_start_z;
STM_data.STM_end_z=STM_end_z;
STM_data.omega_mod=omega_mod;
STM_data.kmod=kmod;
STM_data.mask=mask;
STM_data.STM_center_krefy_loc=STM_center_krefy_loc;
STM_data.STM_width_fact=STM_width_fact;
STM_data.gaussian_STM=gaussian_STM;
STM_data.eps_ij_n=eps_ij_n;
STM_data.Dneps_ij_n=Dneps_ij_n;
STM_data.D2neps_ij_n=D2neps_ij_n;
STM_data.STM_start_y=STM_start_y;
STM_data.STM_end_y=STM_end_y;
%--------------------------------------------------------------------------
figure('position',[0 0 1500 600])
subplot(1,2,1)
colormap jet
disorder_refractive_index=sqrt(eps_ij_n(330));
imagesc([0 kref*dz*(Nz-1)],[0 kref*dy*(Ny-1)],disorder_refractive_index);  
% Refractive index = sqrt(dielectric constant)
title('$Refractive~index~(\eta_{z,y})~distribution$','Interpreter','Latex')
xlabel('$k_{ref}z$','Interpreter','Latex')
ylabel('$k_{ref}y$','Interpreter','Latex')
hold on
line([STM_start_z*kref*dz (STM_start_z+grat_width-1)*kref*dz ...
    (STM_start_z+grat_width-1)*kref*dz ...
    STM_start_z*kref*dz  STM_start_z*kref*dz ], ...
    [STM_start_y*kref*dy STM_start_y*kref*dy STM_end_y*kref*dy ...
    STM_end_y*kref*dy  STM_start_y*kref*dy], ...
    'color','white','LineWidth',2)
%hold on
%line([start_slab1*kref*dz (start_slab1+scat_width-1)*kref*dz (start_slab1+ ...
%    scat_width-1)*kref*dz  start_slab1*kref*dz  start_slab1*kref*dz ],[0 0 ...
%    Ny*kref*dy  Ny*kref*dy  0],'LineWidth',2);
    % Plot the boundary of the disorder
%hold on
%line([start_slab2*kref*dz (start_slab2+scat_width-1)*kref*dz (start_slab2+ ...
 %   scat_width-1)*kref*dz  start_slab2*kref*dz  start_slab2*kref*dz ],[0 0 ...
  %  Ny*kref*dy  Ny*kref*dy  0],'LineWidth',2);
    % Plot the boundary of the disorder
axis equal tight
colorbar
set(gca,'FontSize',22)
axis xy equal tight
%--------------------------------------------------------------------------
subplot(1,2,2)
plot(disorder_refractive_index(:,floor((STM_start_z+STM_end_z)/2)),...
    (0:init_data.Ny-1).*init_data.kref*init_data.dy);
ylim([0 (init_data.Ny-1).*init_data.kref*init_data.dy]);
set(gca, 'XDir','reverse')
set(gca,'FontSize',22)
end

