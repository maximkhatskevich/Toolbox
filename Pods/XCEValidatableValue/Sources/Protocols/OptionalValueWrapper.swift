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

/**
 Emphasizes the fact that the value stored inside
 can be considered as 'valid' even if it's empty,
 so it's 'validValue()' function returns optional value.
 */
public
protocol OptionalValueWrapper: ValueWrapper {}

//---

/*

 NOTE: there is nothing to validate (if it would be 'Validatable')
 unless it's 'CustomValidatable' - because 'value' is allowed
 to be either 'nil' or non-'nil', there is nothing we can
 validate automatically, so only 'CustomValidatable' makes sense.

 */

// MARK: - Reporting

public
extension OptionalValueWrapper
    where
    Self: Validatable
{
    func prepareInvalidValueReport(
        with failedConditions: [String]
        ) -> (title: String, message: String)
    {
        return (
            "Value validation failed",
            "Value is non-empty, but invalid, because it does not satisfy following conditions: \(failedConditions)."
        )
    }
}

// MARK: - Reporting + DisplayNamed

public
extension OptionalValueWrapper
    where
    Self: Validatable,
    Self: DisplayNamed
{
    func prepareInvalidValueReport(
        with failedConditions: [String]
        ) -> (title: String, message: String)
    {
        return (
            "\"\(self.displayName)\" validation failed",
            "\"\(self.displayName)\" is non-empty, but invalid, because it does not satisfy following conditions: \(failedConditions)."
        )
    }
}

// MARK: - Validation + CustomValidatable

public
extension OptionalValueWrapper
    where
    Self: CustomValidatable,
    Self.Validator: ValueValidator,
    Self.Validator.Input == Self.Value
{
    func validate() throws
    {
        _ = try validValue()
    }

    /**
     This is a special getter that allows to get an optional valid value
     OR collect an error, if stored value is invalid.
     This helper function allows to collect issues from multiple
     validateable values wihtout throwing an error immediately,
     but received value should ONLY be used/read if the 'collectError'
     is empty in the end.
     */
    func validValue(
        _ accumulateValidationError: inout [ValidationError]
        ) throws -> Value?
    {
        let result: Value?

        //---

        do
        {
            result = try validValue()
        }
        catch let error as ValidationError
        {
            accumulateValidationError.append(error)
            result = nil
        }
        catch
        {
            // anything except 'ValueValidationFailed'
            // should be thrown to the upper level
            throw error
        }

        //---

        return result
    }

    /**
     It returns whatever is stored in 'value',
     or throws 'ValidationFailed' error if
     'value' is not 'nil' and at least one of
     the custom conditions from Validator has failed.
     */
    func validValue() throws -> Value?
    {
        guard
            let result = value
        else
        {
            // 'nil' is allowed
            return nil
        }

        //---

        // non-'nil' value must be checked againts requirements

        var failedConditions: [String] = []

        Validator.conditions.forEach
        {
            do
            {
                try $0.validate(value: result)
            }
            catch
            {
                if
                    let error = error as? ConditionUnsatisfied
                {
                    failedConditions.append(error.condition)
                }
            }
        }

        //---

        guard
            failedConditions.isEmpty
        else
        {
            throw ValidationError.valueIsNotValid(
                origin: reference,
                value: result,
                failedConditions: failedConditions,
                report: prepareInvalidValueReport(with: failedConditions)
            )
        }

        //---

        return result
    }
}