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
 Data model type that supposed to store all important data
 in various validatable value properties. Such properties will be automatically
 checked for validity each time when whole entity is being tested for validity.
 Those property will be also automatically encoded and decoded.
 */
public
protocol ValidatableEntity: Codable, Equatable, Validatable, DisplayNamed
{
    static
    var reportReview: EntityReportReview { get }
}

//---

public
extension ValidatableEntity
{
    var allValidatableMembers: [Validatable]
    {
        return Mirror(reflecting: self)
            .children
            .map{ $0.value }
            .compactMap{ $0 as? Validatable }
    }

    /**
     Validates all validateable values conteined inside the entity,
     throws 'EntityValidationFailed' if any issues found.

     Note, that validate does NOT rely on 'valid()' function,
     because 'valid()' function supposed to return a custom
     representation of the entity in case it's fully valid,
     but we should make NO assumption about what it is and
     which properties will be evaluated for validity during
     preparation of this representation. That means there is no
     guarantee that all presented validatable values of the entity
     will be validated during this process.
     */
    func validate() throws
    {
        var issues: [ValidationError] = []

        //---

        try allValidatableMembers.forEach{

            do
            {
                try $0.validate()
            }
            catch let error as ValidationError
            {
                issues.append(error)
            }
            catch
            {
                // throw any unexpected erros right away
                throw error
            }
        }

        //---

        if
            !issues.isEmpty
        {
            throw issues.asValidationIssues(for: self)
        }
    }
}

public
extension Array
    where
    Element == ValidationError
{
    func asValidationIssues<E: ValidatableEntity>(
        for entity: E
        ) -> ValidationError
    {
        return .entityIsNotValid(
            origin: entity.displayName,
            issues: self,
            report: type(of: entity).prepareReport(with: self)
        )
    }
}

// MARK: - Reporting

// internal
extension ValidatableEntity
{
    static
    func prepareReport(
        with issues: [ValidationError]
        ) -> Report
    {
        let messages = issues
            .map{

                if
                    $0.hasNestedIssues // report from a nested entity...
                {
                    return """
                    ———
                    \($0.report.message)
                    ———
                    """
                }
                else
                {
                    return "- \($0.report.message)"
                }
            }
            .joined(separator: "\n")

        //---

        var result: Report = (

            "\"\(self.displayName)\" validation failed",

            """
            \"\(self.displayName)\" validation failed due to the issues listed below.
            \(messages)
            """
        )

        //---

        reportReview(issues, &result)

        //---

        return result
    }
}

public
extension ValidatableEntity
    where
    Self: AutoReporting
{
    static
    var reportReview: EntityReportReview
    {
        // by default, we don't adjust anything in the report
        return { _, _ in }
    }
}
