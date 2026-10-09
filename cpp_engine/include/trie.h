#ifndef TRIE_H
#define TRIE_H

#include <string>
#include <vector>
#include <unordered_map>
#include <set>

class Trie {
private:
    struct Node {
        std::unordered_map<char, Node*> children;
        std::set<int> contactIds;
    };

    Node* root;

    void clear(Node* node);
    bool remove(Node* node, const std::string& word, int id, int depth);

public:
    Trie();
    ~Trie();

    void insert(const std::string& word, int id);
    void remove(const std::string& word, int id);
    std::vector<int> searchPrefix(const std::string& prefix);
};

#endif