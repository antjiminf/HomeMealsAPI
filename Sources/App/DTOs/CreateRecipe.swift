import Vapor

struct CreateRecipe: Content {
    var name: String
    var description: String
    var guide: [String]
    var isPublic: Bool
    var time: Int
    var allergens: [Allergen]
    
    func toRecipe(user: UUID) -> Recipe {
        Recipe(name: self.name,
               description: self.description,
               guide: self.guide,
               isPublic: self.isPublic,
               time: self.time,
               allergens: self.allergens,
               user: user)
    }
}

extension ValidatorResults {
    public struct Guide {
        public let isValidGuide: Bool
    }
    
    public struct Allergens {
        public let isValidAllergens: Bool
    }
}

extension ValidatorResults.Guide: ValidatorResult {
    public var isFailure: Bool {
        !self.isValidGuide
    }

    public var successDescription: String? {
        "is a valid"
    }

    public var failureDescription: String? {
        "is not valid. Please write a guide with at least 3 steps having each any instruction."
    }
}

extension ValidatorResults.Allergens: ValidatorResult {
    public var isFailure: Bool {
        !self.isValidAllergens
    }

    public var successDescription: String? {
        "is a valid list of allergens"
    }

    public var failureDescription: String? {
        "not valid. The list of allergens available is: \(Allergen.allCases.map({$0.rawValue}))"
    }
}

extension Validator where T == [String] {
    public static var guide: Validator<T> {
        .init { input in
            guard input.count >= 3
            else {
                return ValidatorResults.Guide(isValidGuide: false)
            }
            for step in input {
                if step.isEmpty {
                    return ValidatorResults.Guide(isValidGuide: false)
                }
            }
            return ValidatorResults.Guide(isValidGuide: true)
        }
    }
    
    public static var allergens: Validator<T> {
        .init { input in
            let allergens = Allergen.allCases.map({$0.rawValue})
            for allergen in input {
                if !allergens.contains(allergen) {
                    return ValidatorResults.Allergens(isValidAllergens: false)
                }
            }
            return ValidatorResults.Allergens(isValidAllergens: true)
        }
    }
}

extension CreateRecipe: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .alphanumeric)
        validations.add("description", as: String.self, is: .ascii)
        validations.add("guide", as: [String].self, is: .guide)
        validations.add("isPublic", as: Bool.self, is: .valid)
        validations.add("time", as: Int.self, is: .range(1...))
        validations.add("allergens", as: [String].self, is: .allergens)
    }
}
