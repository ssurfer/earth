//  Copyright (C) 2001-2003 Matthew Landauer. All Rights Reserved.
//  
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of version 2 of the GNU General Public License as
//  published by the Free Software Foundation.
//
//  This program is distributed in the hope that it would be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  Further, any
//  license provided herein, whether implied or otherwise, is limited to
//  this program in accordance with the express provisions of the GNU
//  General Public License.  Patent licenses, if any, provided herein do not
//  apply to combinations of this program with other product or programs, or
//  any other product whatsoever.  This program is distributed without any
//  warranty that the program is delivered free of the rightful claim of any
//  third person by way of infringement or the like.  See the GNU General
//  Public License for more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write the Free Software Foundation, Inc., 59
//  Temple Place - Suite 330, Boston MA 02111-1307, USA.
//
// $Id$

#include <cppunit/extensions/HelperMacros.h>

#include <string>
#include "ImageSeq.h"

using namespace Sp;

class testIndexDirectory : public CppUnit::TestFixture
{
public:
	CPPUNIT_TEST_SUITE(testIndexDirectory);
	CPPUNIT_TEST(test);
	CPPUNIT_TEST_SUITE_END();
	
	void test();
	
private:
	void checkSequence(const ImageSeq &sequence, const std::string &format, int width, int height,
		const std::string &path, const std::string &frames);
};

CPPUNIT_TEST_SUITE_REGISTRATION(testIndexDirectory);

#include "Path.h"
#include "IndexDirectory.h"

using namespace Sp;

void testIndexDirectory::test()
{
	// The following set of images should have been created by the
	// script makeTestSequences
	// Format  Width Height Name                        Frames
	// GIF     2     2      test/index/test1.#.gif      1-4
	// GIF     4     4      test/index/test1.#.gif      5
	// SGI     8     8      test/index/test2.@@         8
	// Cineon  4     4      test/index/foo/#            2-3
	// Cineon  8     8      test/index/blah/a/#.cin     6-7
	
	IndexDirectory i;
	std::vector<ImageSeq> r = i.getImageSequences("test/index");
	
	CPPUNIT_ASSERT(r.size() == 5);
	checkSequence(r[0], "GIF", 2, 2, "test/index/test1.#.gif", "1-4");
	checkSequence(r[1], "GIF", 4, 4, "test/index/test1.#.gif", "5");
	checkSequence(r[2], "SGI", 8, 8, "test/index/test2.@@", "8");
	checkSequence(r[3], "Cineon", 4, 4, "test/index/foo/#", "2-3");
	checkSequence(r[4], "Cineon", 8, 8, "test/index/blah/a/#.cin", "6-7");
}

void testIndexDirectory::checkSequence(const ImageSeq &sequence,
	const std::string &format, int width, int height, const std::string &path, const std::string &frames)
{
	CPPUNIT_ASSERT_EQUAL(sequence.format()->formatString(), format);
	CPPUNIT_ASSERT(sequence.dim() == ImageDim(width, height));
	CPPUNIT_ASSERT_EQUAL(sequence.path().fullName(), path);
	CPPUNIT_ASSERT_EQUAL(sequence.framesString(), frames);
}