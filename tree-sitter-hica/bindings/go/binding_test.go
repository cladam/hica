package tree_sitter_hica_test

import (
	"testing"

	tree_sitter "github.com/smacker/go-tree-sitter"
	"github.com/tree-sitter/tree-sitter-hica"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_hica.Language())
	if language == nil {
		t.Errorf("Error loading hica grammar")
	}
}
