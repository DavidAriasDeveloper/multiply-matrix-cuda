#include <iostream>
#include <stdio.h>
#include <time.h>
#include <math.h>

#define N 2000

using namespace std;

void fill_matrix(int *m,char c){
	cout<<"Llenamos matriz "<<endl;
	for(int i=0;i<N;i++){
		for(int j=0;j<N;j++){
			switch(c){
				case 's':
					m[i*N+j] = sin(i);break;
				case 'c':
					m[i*N+j] = cos(i);break;
				case 'z':
					m[i*N+j] = 0;break;
				default: return;
			}
		}
	}
	return;
}
//Multiplicacion en CPU
int multiply_seq(int *m1,int *m2,int *m3){
	cout<<"Multiplicamos con el algoritmo secuencial: \n"<<endl;
	for(int i=0;i<N;i++){
		for(int j=0;j<N;j++){
			for(int k=0;k<N;k++){
				m3[i*N+j]+=m1[j*N+k] * m2[k*N+i];
			}
		}
	}
	return 0;
}

//Multiplicacion en GPU
__global__ void multiply_par(int *a, int *b, int *c) {
	int k=0,suma=0;
	int i= blockIdx.x * blockDim.x + threadIdx.x;
	int j= blockIdx.y * blockDim.y + threadIdx.y;
	if(i < N && j < N){
		for(k=0;k<N;k++){
			suma+=a[j*N+k] * b[k*N+i];
		}
		c[j*N + i]= suma;
	}
}

//Imprimir matrices
void print_matrix(int *m){
	for(int i=0;i<N;i++){
		for(int j=0;j<N;j++){
			cout<<"["<< m[i*N+j] <<"]";
		}
		cout<<endl;
	}
	cout<<endl;
	return;
}

int main(){
	//Declaracion de variables
	int *h_A = (int *)malloc(N*N*sizeof(int *));;
	int *h_B = (int *)malloc(N*N*sizeof(int *));;
	int *h_C = (int *)malloc(N*N*sizeof(int *));;

	clock_t t_i,t_f;
	float tiempo;

	fill_matrix(h_A,'s');
	fill_matrix(h_B,'c');
	fill_matrix(h_C,'z');
	//print_matrix(h_A);
	//print_matrix(h_B);

	t_i=clock();
	multiply_seq(h_A,h_B,h_C);
	t_f=clock();

	tiempo= ((double)t_f - t_i) / CLOCKS_PER_SEC;
	cout<<"El tiempo de trabajo con el algoritmo secuencial es de ";
	printf("%f\n\n",tiempo);

	cout<<"Multiplicamos con el algoritmo paralelo: \n"<<endl;

	//Punteros de device
	int *d_A,*d_B,*d_C;

	int size = N * N * sizeof(int);

	cudaMalloc((void **) &d_A, size);//Reservar memoria en GPU
 	cudaMalloc((void **) &d_B, size);
 	cudaMalloc((void **) &d_C, size);

 	cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);//Pasar datos de CPU a GPU
 	cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

	//Invocamos el kernel
	dim3 dimBlock(N*N,2);

	t_i=clock();
	multiply_par<<<1, dimBlock>>>(d_A,d_B,d_C);
	t_f=clock();

	tiempo= ((double)t_f - t_i) / CLOCKS_PER_SEC;
	cout<<"El tiempo de trabajo con el algoritmo en paralelo es de ";
	printf("%f\n\n",tiempo);

	cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);//Pasar datos de GPU a CPU

	//print_matrix(h_C);

  cudaFree(d_A);//Liberar memoria en GPU
 	cudaFree(d_B);
 	cudaFree(d_C);

	free(h_A);
	free(h_B);
	free(h_C);

	return 0;
}
