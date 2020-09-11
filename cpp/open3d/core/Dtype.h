// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2018 www.open3d.org
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// ----------------------------------------------------------------------------

#pragma once

#include <iostream>
#include <string>

namespace open3d {
namespace core {

class Dtype;

namespace dtype {
extern const Dtype Undefined;
extern const Dtype Float32;
extern const Dtype Float64;
extern const Dtype Int32;
extern const Dtype Int64;
extern const Dtype UInt8;
extern const Dtype UInt16;
extern const Dtype Bool;
}  // namespace dtype

class Dtype {
public:
    enum class DtypeCode {
        Undefined,
        Bool,  // Needed to distinguish bool from uint8_t.
        Int,
        UInt,
        Float,
        Object,
    };

    Dtype() : Dtype(DtypeCode::Undefined, 1) {}

    Dtype(DtypeCode dtype_code, int64_t byte_size)
        : dtype_code_(dtype_code), byte_size_(byte_size) {
        (void)dtype_code_;
        (void)byte_size_;
    }

    /// Convert from C++ types to Dtype. Known types are explicitly specialized,
    /// e.g. FromType<float>(). Unsupported type results in an exception.
    template <typename T>
    static inline const Dtype FromType() {
        std::cout << "Unsupported data type" << std::endl;
        return dtype::Undefined;
    }

    int64_t ByteSize() const { return byte_size_; }

    const char *ToString() const { return "hello"; }

    bool operator==(const Dtype &other) const {
        return dtype_code_ == other.dtype_code_ &&
               byte_size_ == other.byte_size_;
    }

    bool operator!=(const Dtype &other) const { return !(*this == other); }

private:
    DtypeCode dtype_code_;
    int64_t byte_size_;
};

template <>
inline const Dtype Dtype::FromType<float>() {
    return dtype::Float32;
}

template <>
inline const Dtype Dtype::FromType<double>() {
    return dtype::Float64;
}

template <>
inline const Dtype Dtype::FromType<int32_t>() {
    return dtype::Int32;
}

template <>
inline const Dtype Dtype::FromType<int64_t>() {
    return dtype::Int64;
}

template <>
inline const Dtype Dtype::FromType<uint8_t>() {
    return dtype::UInt8;
}

template <>
inline const Dtype Dtype::FromType<uint16_t>() {
    return dtype::UInt16;
}

template <>
inline const Dtype Dtype::FromType<bool>() {
    return dtype::Bool;
}

}  // namespace core
}  // namespace open3d
