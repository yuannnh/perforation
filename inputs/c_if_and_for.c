void foo(int* a, int *b) {
  if (a[0] > 1) {
    b[0] = 10;
    b[1] = 3;
    b[0] = 1;
    b[1] = 0;
  }
}

void bar(float x, float y); // just a declaration

void test() {
	int a,b;
	a = 5 + 6;
	b = 10 - a;
	a = b*a;
	a+=1;
	int c = a * b;
}

void bang(int* a, int v) {
    for (int i = 0; i < v; i = i+1) {
        a[i] -= i;
    }
    a[0] = a[1] + 5;
}
