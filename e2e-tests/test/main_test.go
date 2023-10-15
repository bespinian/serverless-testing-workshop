package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformJokesterFunction(t *testing.T) {
	t.Parallel()

	testID := strings.ToLower(random.UniqueId())
	resourceSuffix := "-test-" + testID

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
		Vars: map[string]any{
			"environment":     "test",
			"resource_suffix": resourceSuffix,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	functionName := terraform.Output(t, terraformOptions, "function_name")

	expectedFunctionName := "jokester" + resourceSuffix
	if functionName != expectedFunctionName {
		t.Errorf("Expected function name to be %s, got %s", expectedFunctionName, functionName)
	}
}
