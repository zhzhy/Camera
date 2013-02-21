/*
 * packed and tested by Peter.Xu @ 2009.8
 */
#ifndef	__LM_YUV2RGB_H__
#define	__LM_YUV2RGB_H__

#ifdef __cplusplus
extern "C" {
#endif
// doing the convert
int yuv2rgb_convert(unsigned char *src0,unsigned char *src1,
		unsigned char *src2, unsigned char *dst_ori, int width, int height);
#ifdef __cplusplus
}
#endif

#endif

