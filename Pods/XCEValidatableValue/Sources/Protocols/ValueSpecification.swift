/*

 MIT License

 Copyright (c) 2016 Maxim Khatskevich (maxim@khatskevi.ch)

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 */

//---

/**
 Describes custom value type for a wrapper.
 */
public
protocol ValueSpecification: DisplayNamed
{
    associatedtype Value

    static
    var conditions: [Condition<Value>] { get }

    /**
     Controls whatever the built-in validation should be performed
     in case the 'Value' supports validation. 'true' by default,
     add 'IgnoreBuiltInValidation' conformance to switch to 'false'.
     */
    static
    var performBuiltInValidation: Bool { get }

    static
    var reportReview: ValueReportReview { get }
}

public
extension ValueSpecification
{
    static
    var performBuiltInValidation: Bool
    {
        // by default, we do built-in validation
        // in case the 'Value' supports validation
        return true
    }
}

// internal
extension ValueSpecification
{
    static
    func defaultValidationReport(
        with failedConditions: [String]
        ) -> Report
    {
        return (
            "\"\(displayName)\" validation failed",
            "\"\(displayName)\" is invalid, because it does not satisfy following conditions: \(failedConditions)."
        )
    }

    static
    func prepareReport(
        value: Any?,
        failedConditions: [String],
        builtInValidationIssues: [ValidationError],
        suggestedReport: Report
        ) -> Report
    {
        var result = suggestedReport

        let context = ValueReportContext(
            origin: displayName,
            value: value,
            failedConditions: failedConditions,
            builtInValidationIssues: builtInValidationIssues
        )

        //---

        reportReview(context, &result)

        //---

        return result
    }
}

//---

/**
 Protocol-marker for 'ValueSpecification' protocol that
 implements 'performBuiltInValidation' requirement as 'false'.
 */
public
protocol IgnoreBuiltInValidation: ValueSpecification {}

public
extension IgnoreBuiltInValidation
{
    static
    var performBuiltInValidation: Bool
    {
        return false
    }
}

//---

public
protocol NoConditions: ValueSpecification, AutoReporting {}

public
extension NoConditions
{
    static
    var conditions: [Condition<Self.Value>] { return [] }
}

//---

public
extension ValueSpecification
    where
    Self: AutoReporting
{
    static
    var reportReview: ValueReportReview
    {
        // by default, we don't adjust anything in the report
        return { _, _ in }
    }
}
