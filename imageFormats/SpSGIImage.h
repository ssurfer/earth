// $Id$

#ifndef _spsgiimage_h_
#define _spsgiimage_h_

#include "SpImage.h"
#include "SpImageDim.h"

class SpSGIImageFormat: public SpImageFormat
{
	public:
		virtual string formatString() { return "SGI"; };
		virtual SpImage* constructImage();
		virtual bool recognise(unsigned char *buf);
		virtual int sizeToRecognise() { return 2; };
};

class SpSGIImage : public SpImage
{
	public:
		SpSGIImage() { };
		~SpSGIImage() { };
		SpImageDim dim();
		bool valid() { return true; };
	private:
};

#endif