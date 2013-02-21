/*
 * packed and tested by Peter.Xu @ 2009.8
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define yuv2rgb24(y, u,v,rgbVal24) \
{	rgbVal24[0] = clipRGB[(ytable[y] + CBu[u]+32768)>>16  ]; \
	rgbVal24[1] = clipRGB[(ytable[y] + CGu[u]+CGv[v]+32768)>>16]; \
rgbVal24[2] = clipRGB[(ytable[y] + Crv[v]+32768)>>16]; }

#define clip0_255(x) \
	((x)>255?255:(x)<0?0:(x))
#define clip16_240(x) \
	((x)>240?240:(x)<16?16:(x))
#define clip16_235(x) \
	((x)>235?235:(x)<16?16:(x))

long int crv_tab[256];
long int cbu_tab[256];
long int cgu_tab[256];
long int cgv_tab[256];
long int tab_76309[256];
unsigned char clp[1024];

void yuv2rgb_init()
{
	long int crv,cbu,cgu,cgv;
	int i,ind;

	crv = 104597; cbu = 132201; 
	cgu = 25675;  cgv = 53279;

	for (i = 0; i < 256; i++) {
		crv_tab[i] = (i-128) * crv;
		cbu_tab[i] = (i-128) * cbu;
		cgu_tab[i] = (i-128) * cgu;
		cgv_tab[i] = (i-128) * cgv;
		tab_76309[i] = 76309*(i-16);
	}

	for (i=0; i<384; i++)
		clp[i] =0;
	ind=384;
	for (i=0;i<256; i++)
		clp[ind++]=i;
	ind=640;
	for (i=0;i<384;i++)
		clp[ind++]=255;
}


int yuv2rgb_convert(unsigned char *src0,unsigned char *src1,
						  unsigned char *src2,unsigned char *dst_ori,
						  int width,int height)
{    
	int y1,y2,u,v; 
	unsigned char *py1,*py2;
	int i,j, c1, c2, c3, c4;
	unsigned char *d1, *d2;
	unsigned char *tmp_buf;
	int line_len;
    static int initialized;
    
    if (!initialized) {
        yuv2rgb_init();
        initialized = 1;
    }

	py1=src0;
	py2=py1+width;
	d1=dst_ori;
	d2=d1+3*width;
	for (j = 0; j < height; j += 2) { 
		for (i = 0; i < width; i += 2) {

			u = *src1++;
			v = *src2++;

			c1 = crv_tab[v];
			c2 = cgu_tab[u];
			c3 = cgv_tab[v];
			c4 = cbu_tab[u];

			//up-left
			y1 = tab_76309[*py1++];    
			*d1++ = clp[384+((y1 + c1)>>16)];  
			*d1++ = clp[384+((y1 - c2 - c3)>>16)];
			*d1++ = clp[384+((y1 + c4)>>16)];

			//down-left
			y2 = tab_76309[*py2++];
			*d2++ = clp[384+((y2 + c1)>>16)];  
			*d2++ = clp[384+((y2 - c2 - c3)>>16)];
			*d2++ = clp[384+((y2 + c4)>>16)];

			//up-right
			y1 = tab_76309[*py1++];
			*d1++ = clp[384+((y1 + c1)>>16)];  
			*d1++ = clp[384+((y1 - c2 - c3)>>16)];
			*d1++ = clp[384+((y1 + c4)>>16)];

			//down-right
			y2 = tab_76309[*py2++];
			*d2++ = clp[384+((y2 + c1)>>16)];  
			*d2++ = clp[384+((y2 - c2 - c3)>>16)];
			*d2++ = clp[384+((y2 + c4)>>16)];
		}
		d1 += 3*width;
		d2 += 3*width;
		py1+=   width;
		py2+=   width;
	}
	line_len = width * 3;
	tmp_buf = (unsigned char *)malloc(line_len);
	if(tmp_buf == NULL){
		printf("[Yuv2RgbConv::convert]error malloc for tmp_buf.\n");
		return -1;
	}
	for (i = 0, j = height - 1; i < j; i++, j--){
		memcpy(tmp_buf, dst_ori + i * line_len, line_len);
		memcpy(dst_ori + i * line_len, dst_ori + j * line_len, line_len);
		memcpy(dst_ori + j * line_len, tmp_buf, line_len);
	}	

	free(tmp_buf);
	return 0;
}
