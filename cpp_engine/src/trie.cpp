#include "../include/trie.h"

Trie::Trie() {
    root = new Node();
}

Trie::~Trie() {
    clear(root);
}

void Trie::clear(Node* node) {
    for (auto& pair : node->children) {
        clear(pair.second);
    }

    delete node;
}

void Trie::insert(const std::string& word, int id) {
    Node* current = root;

    for (char ch : word) {
        if (current->children.find(ch) == current->children.end()) {
            current->children[ch] = new Node();
        }

        current = current->children[ch];
        current->contactIds.insert(id);
    }
}

bool Trie::remove(
    Node* node,
    const std::string& word,
    int id,
    int depth
) {
    if (depth == static_cast<int>(word.size())) {
        node->contactIds.erase(id);

        if (node->children.empty() && node->contactIds.empty()) {
            return true;
        }

        return false;
    }

    char ch = word[depth];

    if (node->children.find(ch) == node->children.end()) {
        return false;
    }

    Node* child = node->children[ch];

    bool deleteChild = remove(
        child,
        word,
        id,
        depth + 1
    );

    if (deleteChild) {
        delete child;
        node->children.erase(ch);
    }

    return node->children.empty() &&
           node->contactIds.empty();
}

void Trie::remove(
    const std::string& word,
    int id
) {
    remove(root, word, id, 0);
}

std::vector<int> Trie::searchPrefix(
    const std::string& prefix
) {
    Node* current = root;

    for (char ch : prefix) {
        if (current->children.find(ch) ==
            current->children.end()) {
            return {};
        }

        current = current->children[ch];
    }

    return std::vector<int>(
        current->contactIds.begin(),
        current->contactIds.end()
    );
}