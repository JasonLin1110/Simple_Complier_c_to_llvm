void main()
{
   int a;
   int b;

   a = 0;
   b = a + 100 + 123;
   if(a>0){
   	if(b*a==0){
   		printf("1\n");
   	}
   	else printf("2\n");
   }
   else{
   	if(b*a==0){
   		printf("3\n");
   	}
   	else printf("4\n");
   }
   printf("b=%d\n",b);
}
