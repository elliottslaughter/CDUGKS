#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cmath>

#include "Mesh.hh"
#include "Evolution.hh"

extern int testProblem;
extern int D;
extern int Nc;
extern int Nv;
extern int N[3];
extern int NV[3];
extern int effD;

extern double Cv;
extern double R;
extern double gma;
extern double K;


int Nx = N[0];
int Ny = N[1];
int Nz = N[2];


double TimeStep(){

	double timestep = 1/2048.;
	return timestep;
}


void Evolve(double* g, double* b, double* gbar, double* bbar, double* gbarp, double* bbarp, double* Sg, double* Sb, double* rho, double* rhov, double* rhoE, int effD, double dt, double Tf, double Tsim, double dtdump, double* Co_X, double* Co_WX, double* Co_Y, double* Co_WY, double* Co_Z, double* Co_WZ, double* gsigma, double* bsigma, double* gsigma2, double* bsigma2, Cell* mesh, double* gbarpbound, double* bbarpbound, double* rhoh, double* rhovh, double* rhoEh){	

	printf("Initially, timestep = %f\n", dt);
	dt = fmin(TimeStep(), dtdump);
	dt = fmin(dt, Tf-Tsim);
	printf("After fmin's, timestep = %f\n", dt);

	Step1a(g, b, gbar, bbar, gbarp, bbarp, Sg, Sb, rho, rhov, rhoE, effD, dt, Co_X, Co_WX, Co_Y, Co_WY, Co_Z, Co_WZ);
	Step1b(gbarp, bbarp, effD, gsigma, bsigma, gsigma2, bsigma2, mesh, gbarpbound, bbarpbound);
	Step1c(gbar, bbar, gbarpbound, bbarpbound, effD, Co_X, Co_WX, Co_Y, Co_WY, Co_Z, Co_WZ, gsigma2, bsigma2, dt);
	
	Step2a(gbar, bbar, Co_X, Co_Y, Co_Z, Co_WX, Co_WY, Co_WZ, dt, rhoh, rhovh, rhoEh);
	Step2b(gbar, bbar, dt, rhoh, rhovh, rhoEh, Co_X, Co_Y, Co_Z); //gbar, bbar are actually g/b at interface
	Step2c(gbar, bbar, Co_X, Co_Y, Co_Z, mesh, gbarp, bbarp); //gbar, bbar are actually g/b at interface, gbarp/bbarp are actually Fg/Fb -- Recycling memory
	
	Step3();
	
	Step4and5(rho, rhov, rhoE, dt, mesh, gbarp, bbarp, Co_X, Co_Y, Co_Z, Co_WX, Co_WY, Co_WZ, g, b);
	
}


//Step 1: Phibar at interface
void Step1a(double* g, double* b, double* gbar, double* bbar, double* gbarp, double* bbarp, double* Sg, double* Sb, double* rho, double* rhov, double* rhoE, int effD, double dt, double* Co_X, double* Co_WX, double* Co_Y, double* Co_WY, double* Co_Z, double* Co_WZ){

	double tau = 1e-5;
	

	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){
				int sidx = i + Nx*j + Nx*Ny*k; //spatial index

				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){

							
							int idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;
							//printf("idx = %d", idx);

							double u = 0;
							for(int dim = 0; dim < effD; dim++){u += rhov[effD*sidx + dim]/rho[sidx]*rhov[effD*sidx + dim]/rho[sidx];} u = sqrt(u);
							double T = Temperature(rhoE[sidx]/rho[sidx], u);


							tau = visc(T)/rho[sidx]/R/T; // tau = mu/P, P = rho*R*T.



							double c2 = 0;
							double Xi[3] = {Co_X[vx], Co_Y[vy], Co_Z[vz]};

							for(int dim = 0 ; dim < effD; dim++){ c2 += (Xi[dim]-rhov[effD*sidx + dim]/rho[sidx])*(Xi[dim]-rhov[effD*sidx + dim]/rho[sidx]);} //TODO: Potential BUG, did not double check algebra.

							double g_eq = geq(c2, rho[sidx], T);
							double b_eq = g_eq*(Co_X[vx]*Co_X[vx] + Co_Y[vy]*Co_Y[vy] + Co_Z[vz]*Co_Z[vz] + (3-effD+K)*R*T)/2;

							//For Now...
							Sg[sidx] = 0.;
							Sb[sidx] = 0.;

							gbarp[idx] = (2*tau - dt/2.)/(2*tau)*g[idx] + dt/(4*tau)*g_eq + dt/4*Sg[sidx];
							bbarp[idx] = (2*tau - dt/2.)/(2*tau)*b[idx] + dt/(4*tau)*b_eq + dt/4*Sb[sidx];


							
							//printf("g[%d] = %f, g_eq = %f\n",idx, g[idx], g_eq);
							//printf("geq debug: ");
							//printf("c2 = %f, rho[sidx] = %f, T = %f, WX = %f, WY = %f, WZ = %f\n", c2, rho[sidx], T, Co_WX[vx], Co_WY[vy], Co_WZ[vz]);

							//printf("g_eq = %f\n", g_eq);
							//printf("b[idx] = %f\n", b[idx]);
							//printf("gbarp[idx] = %f\n", gbarp[idx]);
						}
					}
				}
			}
		}
	}

}
void Step1b(double* gbarp, double* bbarp, int effD, double* gsigma, double* bsigma, double* gsigma2, double* bsigma2, Cell* mesh, double* gbarpbound, double* bbarpbound){


	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){

				int sidx = i + Nx*j + Nx*Ny*k;

				double xC[3] = {mesh[sidx].x,  mesh[sidx].y,  mesh[sidx].z};
				double sC[3] = {mesh[sidx].dx,  mesh[sidx].dy,  mesh[sidx].dz};

				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){


							//Compute Sigma
							int idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

							

							for(int Dim = 0; Dim < effD; Dim++){
								int IL, IR, JL, JR, KL, KR;

								//Periodic Boundary Conditions
								if(Dim == 0){IL = (i - 1 + N[0])%N[0]; IR = (i + 1)%N[0]; JL = j; JR = j; KL = k; KR = k;} 
								if(Dim == 1){JL = (j - 1 + N[1])%N[1]; JR = (j + 1)%N[1]; IL = i; IR = i; KL = k; KR = k;}
								if(Dim == 2){KL = (k - 1 + N[2])%N[2]; KR = (k + 1)%N[2]; IL = i; IR = i; JL = j; JR = j;}

								//printf("Checking Indices: {IL = %d, i = %d, IR = %d}, {JL = %d, j = %d, JR = %d},  {KL = %d, k = %d, KR = %d}\n", IL, i, IR, JL, j, JR, KL, k, KR);

								/*
								//Reflective Boundary Conditions
								if(Dim == 0){IL = (i - 1); IR = (i + 1);} 
								if(Dim == 1){JL = (j - 1); JR = (j + 1);}
								if(Dim == 2){KL = (k - 1); KR = (k + 1);}

								if(IL < 0){IL = 0;} if(IR == N[0]){IR = N[0] - 1;}
								if(JL < 0){JL = 0;} if(JR == N[1]){JR = N[1] - 1;}
								if(KL < 0){KL = 0;} if(KR == N[2]){KR = N[2] - 1;}
								*/

								int idxL = IL + Nx*JL + Nx*Ny*KL + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;
								int idxR = IR + Nx*JR + Nx*Ny*KR + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

								int sidxL = IL + Nx*JL + Nx*Ny*KL;
								int sidxR = IR + Nx*JR + Nx*Ny*KR;
								

								double xL[3] = {mesh[sidxL].x, mesh[sidxL].y, mesh[sidxL].z};
								double xR[3] = {mesh[sidxR].x, mesh[sidxR].y, mesh[sidxR].z};
								

								//printf("L = {%f, %f, %f}, C = {%f, %f, %f}, R = {%f, %f, %f}\n", xL[0], xL[1], xL[2], xC[0], xC[1], xC[2], xR[0], xR[1], xR[2]);

								double sL[3] = {mesh[sidxL].dx, mesh[sidxL].dy, mesh[sidxL].dz};
								double sR[3] = {mesh[sidxR].dx, mesh[sidxR].dy, mesh[sidxR].dz};
								


								//Computating phisigma, at cell 
								//printf("Checking VanLeer Input: gbarp[idxL] = %f , gbarp[idx] = %f, gbarp[idxR] = %f, xL[Dim] = %f, xC[Dim] = %f, xR[Dim] = %f\n", gbarp[idxL], gbarp[idx], gbarp[idxR], xL[Dim], xC[Dim], xR[Dim]);
								gsigma[effD*idx + Dim] = VanLeer(gbarp[idxL], gbarp[idx], gbarp[idxR], xL[Dim], xC[Dim], xR[Dim]);
								bsigma[effD*idx + Dim] = VanLeer(bbarp[idxL], bbarp[idx], bbarp[idxR], xL[Dim], xC[Dim], xR[Dim]);

								//printf("checking gsigma[%d] = %f\n", effD*idx + Dim, gsigma[effD*idx + Dim] );
								//Computing phisigma, at interface
								for(int Dim2 = 0; Dim2 < effD; Dim2++){

									int IL2, IR2, JL2, JR2, KL2, KR2;

									//Periodic Boundary Conditions
									if(Dim2 == 0){IL2 = (i - 1 + N[0])%N[0]; IR2 = (i + 1)%N[0]; JL2 = j; JR2 = j; KL2 = k; KR2 = k;} 
									if(Dim2 == 1){JL2 = (j - 1 + N[1])%N[1]; JR2 = (j + 1)%N[1]; IL2 = i; IR2 = i; KL2 = k; KR2 = k;}
									if(Dim2 == 2){KL2 = (k - 1 + N[2])%N[2]; KR2 = (k + 1)%N[2]; IL2 = i; IR2 = i; JL2 = j; JR2 = j;}
	
									/*
									//Reflective Boundary Conditions
									if(Dim2 == 0){IL2 = (i - 1); IR2 = (i + 1);} 
									if(Dim2 == 1){JL2 = (j - 1); JR2 = (j + 1);}
									if(Dim2 == 2){KL2 = (k - 1); KR2 = (k + 1);}
	
									if(IL2 < 0){IL2 = 0;} if(IR2 == N[0]){IR2 = N[0] - 1;}
									if(JL2 < 0){JL2 = 0;} if(JR2 == N[1]){JR2 = N[1] - 1;}
									if(KL2 < 0){KL2 = 0;} if(KR2 == N[2]){KR2 = N[2] - 1;}
									*/

									int idxL2 = IL2 + Nx*JL2 + Nx*Ny*KL2 + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;
									int idxR2 = IR2 + Nx*JR2 + Nx*Ny*KR2 + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

									int sidxL2 = IL2 + Nx*JL2 + Nx*Ny*KL2;
									int sidxR2 = IR2 + Nx*JR2 + Nx*Ny*KR2;
									

									double xL2[3] = {mesh[sidxL2].x, mesh[sidxL2].y, mesh[sidxL2].z};
									double xR2[3] = {mesh[sidxR2].x, mesh[sidxR2].y, mesh[sidxR2].z};
									double xC[3] = {mesh[sidx].x,  mesh[sidx].y,  mesh[sidx].z};

									//printf("sidx = %d, sidxL2 = %d, sidxR2 = %d\n", sidx, sidxL2, sidxR2);
									//printf("xL2 = {%f, %f, %f}\n", xL2[0], xL2[1], xL2[2]);
									//printf("xC = {%f, %f, %f}\n", xC[0], xC[1], xC[2]);

									double sL2[3] = {mesh[sidxL2].dx, mesh[sidxL2].dy, mesh[sidxL2].dz};
									double sR2[3] = {mesh[sidxR2].dx, mesh[sidxR2].dy, mesh[sidxR2].dz};
									double sC2[3] = {mesh[sidx].dx,  mesh[sidx].dy,  mesh[sidx].dz};


									//Dim 1 is vector component that is being interpolated.
									//Dim 2 is direction of interpolation.

									gsigma2[effD*effD*idx + effD*Dim + Dim2] = gsigma[effD*idx + Dim] + (sC2[Dim2]/2)*VanLeer(gsigma[effD*idxL2 + Dim], gsigma[effD*idx + Dim], gsigma[effD*idxR2 + Dim], xL2[Dim2], xC[Dim2], xR2[Dim2]);
									bsigma2[effD*effD*idx + effD*Dim + Dim2] = bsigma[effD*idx + Dim] + (sC2[Dim2]/2)*VanLeer(bsigma[effD*idxL2 + Dim], bsigma[effD*idx + Dim], bsigma[effD*idxR2 + Dim], xL2[Dim2], xC[Dim2], xR2[Dim2]);
									
									//printf("xL2[%d], xC[%d], xR2[%d] = %f, %f, %f\n", Dim2, Dim2, Dim2, xL2[Dim2], xC[Dim2], xR2[Dim2]);
									//printf("sidx = %d, gbarp[%d] = %f\n", sidx, idxR, gbarp[idxR]);
									//printf("gsigma = %f\n" ,gsigma[effD*idx + Dim]);
									//printf("gsigma2 = %f\n",gsigma2[effD*effD*idx + effD*Dim + Dim2]);
									
								}



								//Dot Product is just a single product when using rectangular mesh
								//For some reason i was interpolating all the way to next cell.
								//gbarpbound[effD*idx + Dim] = gbarp[idx] + (xR[Dim]-xC[Dim])*gsigma[effD*idx + Dim];
								//bbarpbound[effD*idx + Dim] = bbarp[idx] + (xR[Dim]-xC[Dim])*bsigma[effD*idx + Dim];
								gbarpbound[effD*idx + Dim] = gbarp[idx] + sC[Dim]/2*gsigma[effD*idx + Dim];
								bbarpbound[effD*idx + Dim] = bbarp[idx] + sC[Dim]/2*bsigma[effD*idx + Dim];

							}
						}
					}
				}
			}
		}
	}



}
void Step1c(double* gbar, double* bbar, double* gbarpbound, double*bbarpbound, int effD, double* Co_X, double* Co_WX, double* Co_Y, double* Co_WY, double* Co_Z, double* Co_WZ, double* gsigma2, double* bsigma2, double dt){
	//Compute gbar/bbar @ t=n+1/2  with interface sigma

	int Nx = N[0];
	int Ny = N[1];
	int Nz = N[2];

	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){
				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){

							int idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

							for(int Dim = 0; Dim < effD; Dim++){

								//Phibar at Interface, at t = n+1/2
								gbar[effD*idx + Dim] = gbarpbound[effD*idx + Dim] - dt/2.0*(Co_X[vx]*gsigma2[effD*effD*idx + effD*0 + Dim] + Co_Y[vy]*gsigma2[effD*effD*idx + effD*1 + Dim] + Co_Z[vz]*gsigma2[effD*effD*idx + effD*2 + Dim]);
								bbar[effD*idx + Dim] = bbarpbound[effD*idx + Dim] - dt/2.0*(Co_X[vx]*bsigma2[effD*effD*idx + effD*0 + Dim] + Co_Y[vy]*bsigma2[effD*effD*idx + effD*1 + Dim] + Co_Z[vz]*bsigma2[effD*effD*idx + effD*2 + Dim]);

								//printf("gsigma2[%d] = {%f, %f, %f}\n", effD*idx + Dim, gsigma2[effD*effD*idx + effD*Dim + 0], gsigma2[effD*effD*idx + effD*Dim + 1], gsigma2[effD*effD*idx + effD*Dim + 2]);
								//printf("gbar[%d] = %f\n", effD*idx + Dim, gbar[effD*idx + Dim]);



						
							}


						}
					}
				}
			}
		}
	}

}

//Step 2: Microflux
void Step2a(double* gbar, double* bbar, double* Co_X, double* Co_Y, double* Co_Z, double* Co_WX, double* Co_WY, double* Co_WZ, double dt, double* rhoh, double* rhovh, double* rhoEh){
	//Compute conserved variables W at t+1/2

	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){
				for(int d = 0; d < effD; d++){

				int sidx = i + Nx*j + Nx*Ny*k;

				rhoh[effD*sidx + d] = 0; 

				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){

							int idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

							rhoh[effD*sidx + d] += Co_WX[vx]*Co_WY[vy]*Co_WZ[vz]*gbar[effD*idx + d]; //  what is the purpose of these weights??? why dont I multiply them? :\

							//printf("Wprod[%d] = {%f, %f, %f} = %f, gbar[%d] = %f\n", idx, Co_WX[vx], Co_WY[vy], Co_WZ[vz], Co_WX[vx]*Co_WY[vy]*Co_WZ[vz], effD*idx + d, gbar[effD*idx + d]);

							

						}
					}
				}

				//printf("computed x-boundary rhoh[%d] = %f\n", sidx, rhoh[effD*sidx + 0]);

				}
			}
		}
	}

	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){
			
				int sidx = i + Nx*j + Nx*Ny*k;
				//Inialize E and momentum with source term
				
				//Dim is vector component that was interpolated
				//Dim2 is direction of interpolation (toward interface)
				for(int Dim = 0; Dim < effD; Dim++){
					for(int Dim2 = 0; Dim < effD; Dim++){
						rhovh[effD*effD*sidx + effD*Dim + Dim2] = dt/2*rhoh[effD*sidx+Dim2]*0; //TODO: In future, replace 0 with acceleration field
						rhoEh[effD*sidx + Dim2] = dt/2.*rhoh[effD*sidx + Dim]*0; //TODO: In future replace 0 with u.dot(a), vel dot acc
					}
				}

				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){

							int idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

							double U[3] = {Co_X[vx], Co_Y[vy], Co_Z[vz]};

							//Dim is vector component that was interpolated
							//Dim2 is direction of interpolation (toward interface)
							for(int Dim = 0; Dim < effD; Dim++){
								for(int Dim2 = 0; Dim2 < effD; Dim2++){

									rhovh[effD*effD*sidx + effD*Dim + Dim2] += Co_WX[vx]*Co_WY[vy]*Co_WZ[vz]*U[Dim2]*gbar[effD*idx + Dim]; 
									
								}

								rhoEh[effD*sidx + Dim] += Co_WX[vx]*Co_WY[vy]*Co_WZ[vz]*bbar[effD*idx + Dim]; 
							}	
						}
					}
				}

				//printf("Half-Step x-dim W[%d] = {%f, %f, %f}\n", sidx, rhoh[effD*sidx + 0], rhovh[effD*effD*sidx + effD*0 + 0], rhoEh[effD*sidx + 0]);

			}
		}
	}


}
void Step2b(double* gbar, double* bbar, double dt, double* rhoh, double* rhovh, double* rhoEh, double* Co_X, double* Co_Y, double* Co_Z){

	double tau;
	double u;
	double T;
	int idx;
	int sidx;
	double g_eq;
	double b_eq;

	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){
				sidx = i + Nx*j + Nx*Ny*k;
				for(int dim2 = 0; dim2 < effD; dim2++){ 

					u = 0;
					//Dim is vector component that was interpolated
					//Dim2 is direction of interpolation (toward interface)
					for(int dim = 0; dim < effD; dim++){u += rhovh[effD*effD*sidx + dim*effD + dim2]/rhoh[effD*sidx + dim2]*rhovh[effD*effD*sidx + dim*effD + dim2]/rhoh[effD*sidx + dim2];} u = sqrt(u);
					T = Temperature(rhoEh[effD*sidx+ dim2]/rhoh[effD*sidx + dim2], u);

					tau = visc(T)/rhoh[effD*sidx + dim2]/R/T;

					for(int vx = 0; vx < NV[0]; vx++){
						for(int vy = 0; vy < NV[1]; vy++){
							for(int vz = 0; vz < NV[2]; vz++){
								idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;


							
								double c2 = 0;
								double Xi[3] = {Co_X[vx], Co_Y[vy], Co_Z[vz]};

								for(int dim = 0 ; dim < effD; dim++){ c2 += (Xi[dim]-rhovh[effD*effD*sidx + effD*dim + dim2]/rhoh[effD*sidx + dim2])*(Xi[dim]-rhovh[effD*effD*sidx + effD*dim + dim2]/rhoh[effD*sidx + dim2]);} //TODO: Potential BUG, did not double check algebra.

								g_eq = geq(c2, rhoh[effD*sidx + dim2], T);
								b_eq = g_eq*(Co_X[vx]*Co_X[vx] + Co_Y[vy]*Co_Y[vy] + Co_Z[vz]*Co_Z[vz] + (3-effD+K)*R*T)/2;

								// this is actually the original distribution function, recycling memory from gbar
								gbar[effD*idx + dim2] = 2*tau/(2*tau + dt/2.)*gbar[effD*idx + dim2] + dt/(4*tau + dt)*g_eq + dt*tau/(4*tau + dt)*0; //TODO replace this last *0 with source term 
								bbar[effD*idx + dim2] = 2*tau/(2*tau + dt/2.)*bbar[effD*idx + dim2] + dt/(4*tau + dt)*b_eq + dt*tau/(4*tau + dt)*0; //TODO replace this last *0 with source term
							}
						}
					}
				}
			}
		}
	}

}
void Step2c(double* gbar, double* bbar, double* Co_X, double* Co_Y, double* Co_Z, Cell* mesh, double* Fg, double* Fb){
	int sidx;
	int idx;
	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){

				//Spatial Index
				sidx = i + Nx*j + Nx*Ny*k;

				//Area of Interface
				double A[3] = {mesh[sidx].dy*mesh[sidx].dz, mesh[sidx].dx*mesh[sidx].dz, mesh[sidx].dx*mesh[sidx].dy};

				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){
							idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;
								
							Fg[idx] = 0;
							Fb[idx] = 0;

							for(int dim = 0; dim < effD; dim++){
								int IL, JL, KL;

								//Periodic Boundary Conditions
								if(dim == 0){IL = (i - 1 + N[0])%N[0]; JL = j; KL = k;} 
								if(dim == 1){JL = (j - 1 + N[1])%N[1]; IL = i; KL = k;}
								if(dim == 2){KL = (k - 1 + N[2])%N[2]; IL = i; JL = j;}

								int idxL = IL + Nx*JL + Nx*Ny*KL + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;

								double Xi[3] = {Co_X[vx], Co_Y[vy], Co_Z[vz]};

								Fg[idx] += Xi[dim]*A[dim]*(gbar[effD*idx + dim] - gbar[effD*idxL + dim]);
								Fb[idx] += Xi[dim]*A[dim]*(bbar[effD*idx + dim] - bbar[effD*idxL + dim]);

							}

						//printf("Flux[%d] = {%f, %f}\n", idx, Fg[idx], Fb[idx]);
						}
					}
				}
			}
		}
	}
}

//Step 3: Source Terms
void Step3(){


}

//Step 4: Update Conservative Variables W at cell center at next timestep
//Step 5: Update Phi at cell center at next time step
void Step4and5(double* rho, double* rhov, double* rhoE, double dt, Cell* mesh, double* Fg, double* Fb, double* Co_X, double* Co_Y, double* Co_Z, double* Co_WX, double* Co_WY, double* Co_WZ, double* g, double* b){
	int idx; 
	int sidx; //spatial index
	double V; // Cell Volume
	double tgo; //old tg
	double tbo; //old tb
	double tg; 
	double tb;
	double g_eqo; //old g_eq
	double g_eq;
	double b_eqo; //odl b_eq
	double b_eq;

	for(int i = 0; i < N[0]; i++){
		for(int j = 0; j < N[1]; j++){
			for(int k = 0; k < N[2]; k++){
	
				sidx = i + Nx*j + Nx*Ny*k;

				V = mesh[sidx].dx * mesh[sidx].dy * mesh[sidx].dz;
				for(int vx = 0; vx < NV[0]; vx++){
					for(int vy = 0; vy < NV[1]; vy++){
						for(int vz = 0; vz < NV[2]; vz++){
							
							idx = i + Nx*j + Nx*Ny*k + Nx*Ny*Nz*vx + Nx*Ny*Nz*NV[0]*vy + Nx*Ny*Nz*NV[0]*NV[1]*vz;
							double Xi[3] = {Co_X[vx], Co_Y[vy], Co_Z[vz]};

							//Compute Flow velocity uo and temperature To before updating rho
							double uo = 0; //old flow velocity
							for(int dim = 0; dim < effD; dim++){uo += rhov[effD*sidx + dim]/rho[sidx]*rhov[effD*sidx + dim]/rho[sidx];} uo = sqrt(uo);
							double To = Temperature(rhoE[sidx]/rho[sidx], uo); //old temp
							//Compute old taus
							tgo = visc(To)/rho[sidx]/R/To; // tau = mu/P, P = rho*R*T.
							tbo = tgo/1.0; //TODO replace 1.0 with prandtl number.

							//Compute old eq's
							double c2 = 0;
							for(int dim = 0 ; dim < effD; dim++){ c2 += (Xi[dim]-rhov[effD*sidx + dim]/rho[sidx])*(Xi[dim]-rhov[effD*sidx + dim]/rho[sidx]);} //TODO: Potential BUG, did not double check algebra.
							g_eqo = geq(c2, rho[sidx],To);
							b_eqo = g_eqo*(Co_X[vx]*Co_X[vx] + Co_Y[vy]*Co_Y[vy] + Co_Z[vz]*Co_Z[vz] + (3-effD+K)*R*To)/2;


							//Step 4: Update W at cell center
							rho[sidx] += -(dt/V*Fg[idx] + dt*0)*Co_WX[vx]*Co_WY[vy]*Co_Z[vz]; //TODO replace 0 with source term.
							for(int dim = 0; dim < effD; dim++){
								rhov[effD*sidx + dim] += -dt/V*Fg[idx]*Xi[dim]*Co_WX[vx]*Co_WY[vy]*Co_Z[vz];
							}

							rhoE[sidx] += -dt/V*Fb[idx]*Co_WX[vx]*Co_WY[vy]*Co_Z[vz];

							//Step 5: Update Phi at cell center, need new eq and tau
							//Compute Flow velocity u and temperature T
							double u = 0; //old flow velocity
							for(int dim = 0; dim < effD; dim++){u += rhov[effD*sidx + dim]/rho[sidx]*rhov[effD*sidx + dim]/rho[sidx];} u = sqrt(u);
							double T = Temperature(rhoE[sidx]/rho[sidx], u); //old temp
							//Compute new taus
							tg = visc(T)/rho[sidx]/R/T; // tau = mu/P, P = rho*R*T.
							tb = tg/1.0; //TODO replace 1.0 with Prandtl number.

							//printf("taus are = {%f, %f}\n", tg, tb);

							//Compute new eq's
							c2 = 0; //reset c2 from beforeßßß
							for(int dim = 0 ; dim < effD; dim++){ c2 += (Xi[dim]-rhov[effD*sidx + dim]/rho[sidx])*(Xi[dim]-rhov[effD*sidx + dim]/rho[sidx]);} //TODO: Potential BUG, did not double check algebra.
							g_eq = geq(c2, rho[sidx], T);
							b_eq = g_eq*(Co_X[vx]*Co_X[vx] + Co_Y[vy]*Co_Y[vy] + Co_Z[vz]*Co_Z[vz] + (3-effD+K)*R*To)/2;


							//Update phi
							double testold = g[idx];
							g[idx] = (g[idx] + dt/2*(g_eq/tg + (g_eqo-g[idx])/tgo - dt/V*Fg[idx] + dt*0))/(1+dt/2/tg); //TODO replace 0 with source term
							b[idx] = (b[idx] + dt/2*(b_eq/tb + (b_eqo-b[idx])/tbo - dt/V*Fb[idx] + dt*0))/(1+dt/2/tb); //TODO replace 0 with source term

							if(sidx == 0)
							printf("test change testold[%d] = %0.20f\n", idx, g[idx]-testold);
						}
					}
				}
			}
		}
	}
}


