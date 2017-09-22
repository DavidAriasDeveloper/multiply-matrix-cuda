#include <iostream>
#include <stdio.h>
#include <time.h>

#define N 5

using namespace std;

void fill_matrix(int m[N][N],char c){
	cout<<"Llenamos matriz: "<<endl;
	for(int i=0;i<N;i++){
		for(int j=0;j<N;j++){
			switch(c){
				case 's':
					m[i][j] = int(i+j);break;
				case 'z':
					m[i][j] = 0;break;
				default: return;
			}
		}
	}
	return;
}
//Multiplicacion en CPU
int multiply_seq(int m1[N][N], int m2[N][N],int m3[N][N]){
	cout<<"Multiplicamos con el algoritmo secuencial: \n"<<endl;
	for(int i=0;i<N;i++){
		for(int j=0;j<N;j++){
			for(int it_suma=0;it_suma<N;it_suma++){
				m3[i][j]+=m1[i][it_suma] * m2[it_suma][j];
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
void print_matrix(int m[N][N]){
	for(int i=0;i<N;i++){
		for(int j=0;j<N;j++){
			cout<<"["<< m[i][j] <<"]";
		}
		cout<<endl;
	}
	cout<<endl;
	return;
}

int main(){
	//Declaracion de variables
	int matrixA[N][N];
	int matrixB[N][N];
	int matrixC[N][N];

	clock_t t_i,t_f;
	float tiempo;

	fill_matrix(matrixA,'s');
	fill_matrix(matrixB,'s');
	fill_matrix(matrixC,'z');
	print_matrix(matrixA);
	print_matrix(matrixB);

	t_i=clock();
	multiply_seq(matrixA,matrixB,matrixC);
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

 	cudaMemcpy(d_A, matrixA, size, cudaMemcpyHostToDevice);//Pasar datos de CPU a GPU
 	cudaMemcpy(d_B, matrixB, size, cudaMemcpyHostToDevice);

	//Invocamos el kernel
	dim3 dimBlock(N*N,2);

	t_i=clock();
	multiply_par<<<1, dimBlock>>>(d_A,d_B,d_C);
	t_f=clock();

	tiempo= ((double)t_f - t_i) / CLOCKS_PER_SEC;
	cout<<"El tiempo de trabajo con el algoritmo en paralelo es de ";
	printf("%f\n\n",tiempo);

	cudaMemcpy(matrixC, d_C, size, cudaMemcpyDeviceToHost);//Pasar datos de GPU a CPU

  cudaFree(d_A);//Liberar memoria en GPU
 	cudaFree(d_B);
 	cudaFree(d_C);

	print_matrix(matrixC);
	return 0;
}
