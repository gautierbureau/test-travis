#include <gtest/gtest.h>
#include "foo.hpp"

TEST(TestFoo, test) {
  ASSERT_EQ(foo(), 12);
}
